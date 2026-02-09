import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Dictionary/model/dictionary_entry.dart';
import '../../../core/app_constants.dart';
import '../model/vocabulary.dart';

/// Service for vocabulary-related API calls
class VocabularyService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Get vocabularies by folder with pagination
  static Future<VocabularyPage> getVocabulariesByFolder(
    int folderId, {
    int page = 0,
    int size = 15,
    String search = '',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/vocabularies/folder/$folderId?page=$page&size=$size&search=$search',
    );
    final response = await http.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return VocabularyPage.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception('Failed to load vocabularies for folder $folderId');
    }
  }

  /// Create a new vocabulary
  static Future<Vocabulary> createVocabulary({
    required DictionaryEntry entry,
    required int folderId,
    required String userDefinedMeaning,
    String? userDefinedPartOfSpeech,
    String? userImageBase64,
    double? imageAlignmentX,
    double? imageAlignmentY,
  }) async {
    final url = Uri.parse('$_baseUrl/vocabularies');

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

    final response = await http.post(
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

  /// Update an existing vocabulary
  static Future<void> updateVocabulary({
    required int vocabularyId,
    required String userDefinedMeaning,
    String? userDefinedPartOfSpeech,
    String? userImageBase64,
    double? imageAlignmentX,
    double? imageAlignmentY,
  }) async {
    final url = Uri.parse('$_baseUrl/vocabularies/$vocabularyId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'userDefinedMeaning': userDefinedMeaning,
        'userDefinedPartOfSpeech': userDefinedPartOfSpeech,
        'userImageBase64': userImageBase64 ?? '',
        'image_alignment_x': imageAlignmentX,
        'image_alignment_y': imageAlignmentY,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update vocabulary: ${response.body}');
    }
  }

  /// Update vocabulary image
  static Future<void> updateVocabularyImage(
    int vocabularyId,
    String imageUrl,
  ) async {
    final url = Uri.parse('$_baseUrl/vocabularies/$vocabularyId/image');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(imageUrl),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update vocabulary image.');
    }
  }

  /// Delete a single vocabulary
  static Future<void> deleteVocabulary(int vocabularyId) async {
    final url = Uri.parse('$_baseUrl/vocabularies/$vocabularyId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete vocabulary. Server response: ${response.body}',
      );
    }
  }

  /// Delete multiple vocabularies
  static Future<void> deleteVocabularies(List<int> vocabularyIds) async {
    final url = Uri.parse('$_baseUrl/vocabularies/batch-delete');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'vocabularyIds': vocabularyIds}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete vocabularies: ${response.body}');
    }
  }

  /// Move vocabularies to another folder
  static Future<void> moveVocabularies(
    List<int> vocabularyIds,
    int targetFolderId,
  ) async {
    final url = Uri.parse('$_baseUrl/vocabularies/batch-move');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'vocabularyIds': vocabularyIds,
        'targetFolderId': targetFolderId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to move vocabularies: ${response.body}');
    }
  }
}
