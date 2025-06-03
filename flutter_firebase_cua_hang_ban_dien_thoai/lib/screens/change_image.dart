import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_platform_mobile_app_development/utils/colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:image_picker_web/image_picker_web.dart';

class ChangeImage extends StatefulWidget {
  final String uid;
  const ChangeImage({Key? key, required this.uid}) : super(key: key);

  @override
  State<ChangeImage> createState() => _ChangeImageState();
}

class _ChangeImageState extends State<ChangeImage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? _profileImageUrl;
  Uint8List? _selectedImageBytes;
  File? _selectedImageFile;
  Uint8List? _imageBytes;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    // _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.uid)
              .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          _profileImageUrl = data['image'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')));
    }
  }

  // Future<void> _pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //
  //   try {
  //     if (kIsWeb) {
  //       Uint8List? imageBytes = await ImagePickerWeb.getImageAsBytes();
  //       if (imageBytes != null) {
  //         setState(() {
  //           _selectedImageBytes = imageBytes;
  //           _selectedImageFile = null;
  //         });
  //       }
  //     } else {
  //       final XFile? pickedFile = await picker.pickImage(
  //         source: ImageSource.gallery,
  //         maxWidth: 800,
  //         maxHeight: 800,
  //         imageQuality: 70,
  //       );
  //       if (pickedFile != null) {
  //         setState(() {
  //           _selectedImageFile = File(pickedFile.path);
  //         });
  //         _selectedImageBytes = await pickedFile.readAsBytes();
  //       }
  //     }
  //   } catch (e) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('Lỗi khi chọn ảnh: $e')));
  //   }
  // }

  Future<void> _pickImage() async {
    if (!kIsWeb) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo access denied')));
        return;
      }
    }
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageFile = kIsWeb ? null : File(pickedFile.path);
          _profileImageUrl = "data:image/png;base64,${base64Encode(bytes)}";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (_selectedImageBytes == null && _selectedImageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ảnh mới')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String imageBase64 = '';
      if (_selectedImageBytes != null) {
        imageBase64 =
            "data:image/png;base64,${base64Encode(_selectedImageBytes!)}";
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'image': imageBase64});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật ảnh đại diện thành công!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi lưu ảnh: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildImageWidget() {
    if (_selectedImageBytes != null) {
      return CircleAvatar(
        radius: 52,
        backgroundImage: MemoryImage(_selectedImageBytes!),
      );
    }

    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
      if (_profileImageUrl!.startsWith('data:image')) {
        try {
          final imageData = _profileImageUrl!.split(',')[1];
          final imageBytes = base64Decode(imageData);
          return CircleAvatar(
            radius: 52,
            backgroundImage: MemoryImage(imageBytes),
          );
        } catch (e) {
          print("Lỗi khi giải mã ảnh base64: $e");
        }
      }
    }

    return const CircleAvatar(
      radius: 52,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, size: 50, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Thay đổi ảnh đại diện",
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
                      SizedBox(height: 20),
                      Center(
                        child: Stack(
                          children: [
                            _buildImageWidget(),
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
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primaryColor,
                          minimumSize: Size(double.infinity, 45),
                        ),
                        child: Text(
                          "Lưu thay đổi",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
