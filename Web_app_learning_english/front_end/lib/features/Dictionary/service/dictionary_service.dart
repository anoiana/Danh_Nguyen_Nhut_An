import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_constants.dart';
import '../model/dictionary_entry.dart';

/// Service for dictionary-related API calls
class DictionaryService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Lookup a word in the external dictionary API
  static Future<List<DictionaryEntry>> lookupWord(String word) async {
    final url = Uri.parse(
      'https://api.dictionaryapi.dev/api/v2/entries/en/$word',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((e) => DictionaryEntry.fromJson(e)).toList();
    } else if (response.statusCode == 404) {
      throw Exception('Không tìm thấy từ này trong từ điển.');
    } else {
      throw Exception('Lỗi khi tra từ từ dịch vụ bên ngoài.');
    }
  }

  /// Translate a word using backend API
  static Future<String> translateWord(String word) async {
    final url = Uri.parse('$_baseUrl/translate/$word');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return "Lỗi: ${response.statusCode}";
      }
    } catch (e) {
      return "Lỗi kết nối.";
    }
  }
}
