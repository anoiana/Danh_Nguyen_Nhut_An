import 'dart:convert';
import 'package:image_picker/image_picker.dart';

/// Service for handling image picking and encoding
class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery and return as Base64 string
  static Future<String?> pickAndEncodeImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1000,
    );
    if (image == null) return null;

    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }
}
