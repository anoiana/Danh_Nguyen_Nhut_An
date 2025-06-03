import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/widgets/full_screen_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

enum TypeMessage { text, image }

class ChatScreen extends StatefulWidget {
  final String customerId;
  final String role;

  const ChatScreen({super.key, required this.customerId, required this.role});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

// ok

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late String _currentUserId;
  final String _adminId = 'BnVj2FLLvLN8DQJ7ewL2pEUA8Nw2';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.role == 'Admin' ? _adminId : widget.customerId;
    _focusNode.addListener(_onFocusChange);
    _updateMessageReadStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        MediaQuery.of(context).viewInsets.bottom;
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() {});
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Widget _buildAvatar(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final avatarUrl = userData['image'] as String?;

          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            if (avatarUrl.startsWith('data:image')) {
              try {
                final imageData = avatarUrl.split(',')[1];
                final imageBytes = base64Decode(imageData);
                return CircleAvatar(
                  radius: 16,
                  backgroundImage: MemoryImage(imageBytes),
                );
              } catch (e) {
                print("Lỗi khi giải mã ảnh base64: $e");
              }
            }
            return CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(avatarUrl),
            );
          }
        }

        return CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.person, size: 20, color: Colors.white),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        setState(() {
          _isLoading = true;
        });

        final bytes = await pickedFile.readAsBytes();
        final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
        await _sendMessage(base64String, TypeMessage.image);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tải ảnh lên: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(
    String content, [
    TypeMessage type = TypeMessage.text,
  ]) async {
    if (content.trim().isNotEmpty) {
      String receiverId = widget.role == 'Admin' ? widget.customerId : _adminId;

      await FirebaseFirestore.instance.collection('chats').add({
        'senderId': _currentUserId,
        'receiverId': receiverId,
        'content': content,
        'time': FieldValue.serverTimestamp(),
        'type': type.index,
        'read': false,
      });

      _messageController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _updateMessageReadStatus() {
    if (widget.role == 'Admin') {
      FirebaseFirestore.instance
          .collection('chats')
          .where('senderId', isEqualTo: widget.customerId)
          .where('receiverId', isEqualTo: _adminId)
          .where('read', isEqualTo: false)
          .get()
          .then((querySnapshot) {
            for (var doc in querySnapshot.docs) {
              doc.reference.update({'read': true});
            }
          });
    } else {
      FirebaseFirestore.instance
          .collection('chats')
          .where('senderId', isEqualTo: _adminId)
          .where('receiverId', isEqualTo: widget.customerId)
          .where('read', isEqualTo: false)
          .get()
          .then((querySnapshot) {
            for (var doc in querySnapshot.docs) {
              doc.reference.update({'read': true});
            }
          });
    }
  }

  Widget _buildMessageContent(Map<String, dynamic> data, TypeMessage type) {
    switch (type) {
      case TypeMessage.text:
        return Text(
          data['content'],
          style: TextStyle(
            color:
                data['senderId'] == _currentUserId
                    ? Colors.white
                    : Colors.black,
            fontSize: 16,
          ),
        );

      case TypeMessage.image:
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => FullScreenImage(imageData: data['content']),
              ),
            );
          },
          child: Hero(
            tag: data['content'],
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(data['content'].split(',')[1]),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
            ),
          ),
        );
    }
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderId'] == _currentUserId;
    TypeMessage messageType = TypeMessage.values[data['type'] as int];
    Timestamp? timestamp = data['time'] as Timestamp?;
    bool isRead = data['read'] ?? false;
    String time = '';

    if (timestamp != null) {
      DateTime dateTime = timestamp.toDate();
      time = DateFormat('HH:mm').format(dateTime);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 1.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: isRead ? Colors.blue : Colors.grey,
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisAlignment:
                isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isCurrentUser) ...[
                _buildAvatar(data['senderId']),
                const SizedBox(width: 8),
              ],
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.65,
                ),
                padding:
                    messageType == TypeMessage.text
                        ? const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        )
                        : const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isCurrentUser ? Colors.blue : Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildMessageContent(data, messageType),
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                _buildAvatar(data['senderId']),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        backgroundColor: Colors.grey.withOpacity(0.1),
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('chats')
                              .orderBy('time', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        // sss
                        final messages =
                            snapshot.data!.docs.where((message) {
                              return (message['senderId'] ==
                                          widget.customerId &&
                                      message['receiverId'] == _adminId) ||
                                  (message['senderId'] == _adminId &&
                                      message['receiverId'] ==
                                          widget.customerId);
                            }).toList();

                        return ListView.builder(
                          reverse: true,
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder:
                              (context, index) =>
                                  _buildMessageItem(messages[index]),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.image, color: Colors.blue),
                              onPressed: _pickAndUploadImage,
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_focusNode);
                                },
                                child: TextField(
                                  controller: _messageController,
                                  focusNode: _focusNode,
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: TextInputAction.send,
                                  maxLines: null,
                                  onTap: () {
                                    if (_scrollController.hasClients) {
                                      _scrollController.animateTo(
                                        0,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  },
                                  onSubmitted: (value) async {
                                    if (value.trim().isNotEmpty) {
                                      await _sendMessage(value);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Nhập tin nhắn...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(25),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, color: Colors.blue),
                              onPressed: () async {
                                if (_messageController.text.trim().isNotEmpty) {
                                  await _sendMessage(_messageController.text);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
