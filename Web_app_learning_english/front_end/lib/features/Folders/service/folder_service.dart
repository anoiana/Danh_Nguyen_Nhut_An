import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:untitled/core/app_constants.dart';
import '../model/folder.dart';

class FolderService {
  final http.Client _client = http.Client();

  Future<FolderPage> getFoldersByUser(
    int userId, {
    int page = 0,
    int size = 15,
    String search = '',
  }) async {
    final url = Uri.parse(
      '${AppConstants.baseUrl}/folders/user/$userId?page=$page&size=$size&search=$search',
    );
    try {
      final response = await _client.get(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
      );

      if (response.statusCode == 200) {
        return FolderPage.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to load folders');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<Folder> createFolder(String folderName, int userId) async {
    final url = Uri.parse('${AppConstants.baseUrl}/folders');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'name': folderName, 'userId': userId}),
    );

    if (response.statusCode == 200) {
      return Folder.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception(
        response.body.replaceAll("\"", ""),
      ); // Backend sends raw string often
    }
  }

  Future<void> updateFolder(int folderId, String newName) async {
    final url = Uri.parse('${AppConstants.baseUrl}/folders/$folderId');
    final response = await _client.put(
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

  Future<void> deleteFolder(int folderId) async {
    final url = Uri.parse('${AppConstants.baseUrl}/folders/$folderId');
    final response = await _client.delete(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete folder. Status code: ${response.statusCode}',
      );
    }
  }
}
