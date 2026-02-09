import '../constants/api_constants.dart';

class ImageHelper {
  static String resolveUrl(String? url) {
    if (url == null || url.isEmpty) {
      return "https://placehold.co/400x300.png?text=No+Image";
    }

    // 1. Nếu là ảnh online (Cloudinary, Firebase...)
    if (url.startsWith("http")) {
      return url;
    }

    // 2. Nếu là ảnh upload local (/uploads/tour-abc.jpg)
    // Loại bỏ dấu '/' ở đầu nếu có để tránh trùng (ví dụ: http://ip:3000//uploads)
    final cleanPath = url.startsWith('/') ? url.substring(1) : url;
    
    // Nối với Catalog URL (Port 3000 - nơi chứa folder uploads)
    return "${ApiConstants.catalogUrl}/$cleanPath";
  }
}