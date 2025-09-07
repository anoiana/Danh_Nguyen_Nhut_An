// lib/api/image_service.dart (Đổi tên file cho đúng)
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  // Hàm chọn ảnh và trả về chuỗi Base64
  static Future<String?> pickAndEncodeImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Giảm chất lượng ảnh để chuỗi Base64 không quá lớn
      maxWidth: 1000,   // Giảm kích thước ảnh
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    return base64Encode(bytes); // Mã hóa thành Base64
  }
}