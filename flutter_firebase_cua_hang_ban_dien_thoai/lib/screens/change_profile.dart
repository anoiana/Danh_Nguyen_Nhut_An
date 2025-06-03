import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ChangeProfile extends StatefulWidget {
  final String uid;
  const ChangeProfile({Key? key, required this.uid}) : super(key: key);

  @override
  State<ChangeProfile> createState() => _ChangeProfileState();
}

class _ChangeProfileState extends State<ChangeProfile> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  String? _profileImageUrl;
  File? _imageFile;
  Uint8List? _imageBytes;

  ImageProvider? _getImageProvider() {
    if (_imageBytes != null) {
      return MemoryImage(_imageBytes!);
    }
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      if (_profileImageUrl!.startsWith('http')) {
        return NetworkImage(_profileImageUrl!);
      } else {
        const base64Prefix = "base64,";
        String base64Str = _profileImageUrl!;
        int index = _profileImageUrl!.indexOf(base64Prefix);
        if (index != -1) {
          base64Str = _profileImageUrl!.substring(index + base64Prefix.length);
        }
        try {
          final bytes = base64Decode(base64Str);
          return MemoryImage(bytes);
        } catch (e) {
          print("Error decoding base64 image: $e");
          return null;
        }
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // In ChangeProfile.dart
  Future<void> _loadUserData() async {
    print('Loading user data for UID: ${widget.uid}');
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      print('Document exists: ${doc.exists}');
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _profileImageUrl = data['image'] ?? '';
        });
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')));
    }
  }

  // Future<void> _pickImage() async {
  //   if (!kIsWeb) {
  //     final status = await Permission.photos.request();
  //     if (status.isDenied) {
  //       // Quyền bị từ chối, có thể yêu cầu lại
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: const Text('Photo access is required to pick an image.'),
  //           action: SnackBarAction(
  //             label: 'Retry',
  //             onPressed: _pickImage, // Use direct function reference
  //           ),
  //         ),
  //       );
  //       return;
  //     } else if (status.isPermanentlyDenied) {
  //       // Quyền bị từ chối vĩnh viễn, hướng dẫn mở cài đặt
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: const Text('Photo access is permanently denied. Please enable it in settings.'),
  //           action: SnackBarAction(
  //             label: 'Open Settings',
  //             onPressed: openAppSettings,
  //           ),
  //         ),
  //       );
  //       return;
  //     } else if (!status.isGranted) {
  //       // Các trạng thái khác (limited, restricted,...)
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text('Unable to access photos due to restricted permissions.')),
  //       );
  //       return;
  //     }
  //   }
  //
  //   final ImagePicker picker = ImagePicker();
  //   try {
  //     final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
  //     if (pickedFile != null) {
  //       final bytes = await pickedFile.readAsBytes();
  //       setState(() {
  //         _imageBytes = bytes;
  //         _imageFile = kIsWeb ? null : File(pickedFile.path);
  //         _profileImageUrl = "data:image/png;base64,${base64Encode(bytes)}";
  //       });
  //       await _uploadImage();
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error picking image: $e')),
  //     );
  //   }
  // }
  Future<PermissionStatus> _requestPhotoPermission() async {
    if (kIsWeb) return PermissionStatus.granted;

    if (Platform.isAndroid) {
      if (await Permission.photos.isGranted || await Permission.storage.isGranted) {
        return PermissionStatus.granted;
      }

      if (await Permission.photos.request().isGranted) {
        return PermissionStatus.granted;
      }

      if (await Permission.storage.request().isGranted) {
        return PermissionStatus.granted;
      }

      return PermissionStatus.denied;
    } else if (Platform.isIOS) {
      return await Permission.photos.request();
    }
    return PermissionStatus.denied;
  }

  Future<void> _pickImage() async {
    final permissionStatus = await _requestPhotoPermission();

    if (permissionStatus.isDenied || permissionStatus.isRestricted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Photo access is required to pick an image.'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _pickImage,
          ),
        ),
      );
      return;
    }

    if (permissionStatus.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permission permanently denied. Please enable it in Settings.'),
          action: SnackBarAction(
            label: 'Open Settings',
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFile = kIsWeb ? null : File(pickedFile.path);
          _profileImageUrl = "data:image/png;base64,${base64Encode(bytes)}";
        });
        await _uploadImage(); // gọi hàm upload nếu có
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Future<void> _uploadImage() async {
  //   if (_imageFile == null && _profileImageUrl == null) return;
  //
  //   setState(() {
  //     isLoading = true;
  //   });
  //
  //   try {
  //     String? imageData;
  //
  //     if (kIsWeb && _profileImageUrl != null) {
  //       imageData = _profileImageUrl; // Web: đã là base64
  //     } else if (_imageFile != null) {
  //       final bytes = await _imageFile!.readAsBytes();
  //       imageData = "data:image/png;base64,${base64Encode(bytes)}";
  //     v2   }
  //
  //     if (imageData != null) {
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(widget.uid)
  //           .update({'image': imageData});
  //       setState(() {
  //         _profileImageUrl = imageData;
  //       });
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text('Profile image updated')));
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> _uploadImage() async {
    if (_imageBytes == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final imageData = "data:image/png;base64,${base64Encode(_imageBytes!)}";
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'image': imageData});
      setState(() {
        _profileImageUrl = imageData;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .update({
              'fullName': _fullNameController.text.trim(),
              'email': _emailController.text.trim(),
            });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Change Profile",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColor.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundImage: _getImageProvider(),
                              child:
                                  _getImageProvider() == null
                                      ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickImage,
                                child: const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.add_a_photo,
                                    color: AppColor.primaryColor,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: "Full name",
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          } else if (value.length >= 15) {
                            return 'Please enter your full name less than 15 characters';
                          } else {
                            return null;
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          enabled: false,
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryColor,
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
