import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_constants.dart';
import '../model/folder.dart';

/// Service for folder-related API calls
class FolderService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Get folders by user with pagination
  static Future<FolderPage> getFoldersByUser(
    int userId, {
    int page = 0,
    int size = 15,
    String search = '',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/folders/user/$userId?page=$page&size=$size&search=$search',
    );
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
    );

    if (response.statusCode == 200) {
      return FolderPage.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load folders');
    }
  }

  /// Create a new folder
  static Future<Folder> createFolder(String folderName, int userId) async {
    final url = Uri.parse('$_baseUrl/folders');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'name': folderName, 'userId': userId}),
    );

    if (response.statusCode == 200) {
      return Folder.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.replaceAll("\"", ""));
    }
  }

  /// Update folder name
  static Future<void> updateFolder(int folderId, String newName) async {
    final url = Uri.parse('$_baseUrl/folders/$folderId');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'newName': newName}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update folder. Status code: ${response.statusCode}',
      );
    }
  }

  /// Delete a folder
  static Future<void> deleteFolder(int folderId) async {
    final url = Uri.parse('$_baseUrl/folders/$folderId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete folder. Status code: ${response.statusCode}',
      );
    }
  }
}
