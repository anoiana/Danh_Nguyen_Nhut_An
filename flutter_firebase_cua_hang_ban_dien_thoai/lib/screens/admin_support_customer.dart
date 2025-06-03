import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_screen.dart';

class AdminSupportCustomer extends StatefulWidget {
  const AdminSupportCustomer({super.key});

  @override
  State<AdminSupportCustomer> createState() => _AdminSupportCustomerState();
}

class _AdminSupportCustomerState extends State<AdminSupportCustomer> {
  final String _adminId = 'BnVj2FLLvLN8DQJ7ewL2pEUA8Nw2';

  Widget _buildAvatar(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
        backgroundColor: Colors.grey[300],
      );
    }
    return CircleAvatar(
      backgroundColor: Colors.grey[300],
      child: Icon(Icons.person, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messengers')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'Customer')
                .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('chats')
                    .orderBy('time', descending: true)
                    .snapshots(),
            builder: (context, chatSnapshot) {
              if (!chatSnapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              Map<String, dynamic> lastMessages = {};
              Map<String, int> unreadCount = {};

              if (chatSnapshot.data != null) {
                for (var doc in chatSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final customerId =
                      data['senderId'] == _adminId
                          ? data['receiverId']
                          : data['senderId'];

                  if (data['senderId'] != _adminId &&
                      data['receiverId'] != _adminId) {
                    continue;
                  }

                  if (!lastMessages.containsKey(customerId) ||
                      (data['time'] as Timestamp).compareTo(
                            lastMessages[customerId]['time'],
                          ) >
                          0) {
                    lastMessages[customerId] = data;
                  }

                  if (data['receiverId'] == _adminId && !data['read']) {
                    unreadCount[customerId] =
                        (unreadCount[customerId] ?? 0) + 1;
                  }
                }
              }

              final customers = userSnapshot.data!.docs;

              customers.sort((a, b) {
                bool aHasMessage = lastMessages.containsKey(a.id);
                bool bHasMessage = lastMessages.containsKey(b.id);

                if (aHasMessage && bHasMessage) {
                  final aTime = lastMessages[a.id]['time'] as Timestamp;
                  final bTime = lastMessages[b.id]['time'] as Timestamp;
                  return bTime.compareTo(aTime);
                }
                return aHasMessage ? -1 : (bHasMessage ? 1 : 0);
              });

              return ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final customerData = customer.data() as Map<String, dynamic>;
                  final hasMessage = lastMessages.containsKey(customer.id);
                  final lastMessage =
                      hasMessage ? lastMessages[customer.id] : null;
                  final unread = unreadCount[customer.id] ?? 0;

                  return ListTile(
                    leading: _buildAvatar(customerData['image']),
                    title: Text(customerData['fullName']),
                    subtitle:
                        hasMessage
                            ? Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMessage!['content'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  DateFormat('HH:mm').format(
                                    (lastMessage['time'] as Timestamp).toDate(),
                                  ),
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            )
                            : Text('Chưa có tin nhắn'),
                    trailing:
                        unread > 0
                            ? Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                unread.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                            : null,
                    onTap: () {
                      _updateMessageReadStatus(customer.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatScreen(
                                customerId: customer.id,
                                role: 'Admin',
                              ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _updateMessageReadStatus(String customerId) {
    FirebaseFirestore.instance
        .collection('chats')
        .where('senderId', isEqualTo: customerId)
        .where('receiverId', isEqualTo: _adminId)
        .where('read', isEqualTo: false)
        .get()
        .then((querySnapshot) {
          WriteBatch batch = FirebaseFirestore.instance.batch();
          for (var doc in querySnapshot.docs) {
            batch.update(doc.reference, {'read': true});
          }
          return batch.commit();
        });
  }
}
