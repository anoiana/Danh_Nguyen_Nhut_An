import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:untitled/features/Dictionary/model/dictionary_entry.dart';
import '../../../core/app_constants.dart';
import '../model/vocabulary.dart';

class VocabularyService {
  final http.Client _client = http.Client();

  Future<List<DictionaryEntry>> lookupWord(String word) async {
    final url = Uri.parse(
      'https://api.dictionaryapi.dev/api/v2/entries/en/$word',
    );
    try {
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
        return body.map((e) => DictionaryEntry.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        return []; // Return empty list instead of exception for cleaner UI logic sometimes
      } else {
        throw Exception('Lỗi khi tra từ từ dịch vụ bên ngoài.');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<Vocabulary> createVocabulary({
    required DictionaryEntry entry,
    required int folderId,
    required String userDefinedMeaning,
    String? userDefinedPartOfSpeech,
    String? userImageBase64,
    double? imageAlignmentX,
    double? imageAlignmentY,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/vocabularies');

    final body = {
      'userDefinedMeaning': userDefinedMeaning,
      'userDefinedPartOfSpeech': userDefinedPartOfSpeech,
      'userImageBase64': userImageBase64,
      'image_alignment_x': imageAlignmentX,
      'image_alignment_y': imageAlignmentY,
      'word': entry.word,
      'phoneticText': entry.phonetic,
      'audioUrl': entry.audioUrl,
      'folderId': folderId,
      'meanings':
          entry.meanings
              .map(
                (m) => {
                  'partOfSpeech': m.partOfSpeech,
                  'synonyms': m.synonyms,
                  'antonyms': m.antonyms,
                  'definitions':
                      m.definitions
                          .map(
                            (d) => {
                              'definition': d.definition,
                              'example': d.example,
                            },
                          )
                          .toList(),
                },
              )
              .toList(),
    };

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return Vocabulary.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to save vocabulary: ${response.body}');
    }
  }

  Future<VocabularyPage> getVocabulariesByFolder(
    int folderId, {
    int page = 0,
    int size = 20,
    String search = '',
  }) async {
    final url = Uri.parse(
      '${AppConstants.baseUrl}/vocabularies/folder/$folderId?page=$page&size=$size&search=$search',
    );
    final response = await _client.get(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
    );

    if (response.statusCode == 200) {
      return VocabularyPage.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception('Failed to load vocabularies');
    }
  }

  Future<void> updateVocabulary({
    required int id,
    required String meaning,
    String? partOfSpeech,
    String? imageBase64,
    double? alignX,
    double? alignY,
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/vocabularies/$id');
    final body = {
      'userDefinedMeaning': meaning,
      'userDefinedPartOfSpeech': partOfSpeech,
      'userImageBase64': imageBase64,
      'image_alignment_x': alignX,
      'image_alignment_y': alignY,
    };

    final response = await _client.put(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update vocabulary');
    }
  }

  Future<void> deleteVocabulary(int id) async {
    final url = Uri.parse('${AppConstants.baseUrl}/vocabularies/$id');
    final response = await _client.delete(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete vocabulary');
    }
  }

  Future<void> deleteVocabularies(List<int> ids) async {
    final url = Uri.parse('${AppConstants.baseUrl}/vocabularies/bulk-delete');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(ids),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete vocabularies');
    }
  }

  Future<void> moveVocabularies(List<int> vocabIds, int targetFolderId) async {
    final url = Uri.parse(
      '${AppConstants.baseUrl}/vocabularies/move?folderId=$targetFolderId',
    );
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(vocabIds), // Sending List<Integer>
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to move vocabularies');
    }
  }
}
