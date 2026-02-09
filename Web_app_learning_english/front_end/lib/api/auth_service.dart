import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/features/Dictionary/model/dictionary_entry.dart';
import '../features/Authentication/model/login_response.dart';
import '../features/Folders/model/folder.dart';
import '../features/Vocabulary/model/vocabulary.dart';
import '../features/Study_Modes/model/game_session.dart';
import '../features/Study_Modes/model/quiz_session.dart';
import '../features/Study_Modes/model/sentence_check_response.dart';
import '../features/Study_Modes/model/reading_content.dart';
import '../features/Study_Modes/model/listening_content.dart';

class AuthService {
  static const String _baseUrl =
      "https://danhnguyennhutan-production.up.railway.app/api";

  static Future<ListeningContent> generateListeningGame(
    int folderId,
    int level,
    String topic,
    String gameSubType,
  ) async {
    final url = Uri.parse('$_baseUrl/game/generate-listening');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'folderId': folderId,
            'level': level,
            'topic': topic,
            'gameSubType': gameSubType, // <<< GỬI THÊM THAM SỐ NÀY LÊN SERVER
          }),
        )
        .timeout(const Duration(seconds: 90)); // Tăng timeout cho AI

    if (response.statusCode == 200) {
      return ListeningContent.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
      // Cố gắng decode lỗi từ server để hiển thị cho người dùng
      try {
        String errorMessage = utf8
            .decode(response.bodyBytes)
            .replaceAll("\"", "");
        throw Exception(errorMessage);
      } catch (_) {
        throw Exception(
          'Failed to generate listening content: ${response.body}',
        );
      }
    }
  }

  static Future<String> translateWord(String word) async {
    final url = Uri.parse('$_baseUrl/translate/$word');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Phải decode chuỗi JSON (bỏ dấu " ở đầu và cuối)
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return "Lỗi: ${response.statusCode}";
      }
    } catch (e) {
      return "Lỗi kết nối.";
    }
  }

  static Future<ReadingContent> generateReadingGame(
    int folderId,
    int level,
    String topic,
  ) async {
    final url = Uri.parse('$_baseUrl/game/generate-reading');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'folderId': folderId,
            'level': level,
            'topic': topic, // <<< THÊM TOPIC VÀO PAYLOAD
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      return ReadingContent.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception('Failed to generate reading content: ${response.body}');
    }
  }

  static Future<Vocabulary> createVocabulary({
    required DictionaryEntry entry,
    required int folderId,
    required String userDefinedMeaning,
    String? userDefinedPartOfSpeech, // <-- THÊM THAM SỐ MỚI
    String? userImageBase64,
    double? imageAlignmentX,
    double? imageAlignmentY,
  }) async {
    final url = Uri.parse('$_baseUrl/vocabularies');

    final body = {
      'userDefinedMeaning': userDefinedMeaning,
      'userDefinedPartOfSpeech': userDefinedPartOfSpeech, // <-- GỬI LÊN SERVER
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

  // === API SỬA MỘT TỪ VỰNG (ĐÃ CẬP NHẬT) ===
  static Future<void> updateVocabulary({
    required int vocabularyId,
    required String userDefinedMeaning,
    String? userDefinedPartOfSpeech, // <-- THÊM THAM SỐ MỚI
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

  // ... (giữ nguyên các hàm còn lại)
  static Future<void> updateVocabularyImage(
    int vocabularyId,
    String imageUrl,
  ) async {
    final url = Uri.parse('$_baseUrl/vocabularies/$vocabularyId/image');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(imageUrl), // Gửi thẳng chuỗi URL
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update vocabulary image.');
    }
  }

  static Future<GameSession> startGenericGame(
    int userId,
    int folderId,
    String gameType,
  ) async {
    final url = Uri.parse('$_baseUrl/game/start');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'userId': userId,
            'folderId': folderId,
            'gameType': gameType,
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return GameSession.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }

  static Future<QuizSession> startQuizGame(int userId, int folderId) async {
    final url = Uri.parse('$_baseUrl/game/start');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'userId': userId,
            'folderId': folderId,
            'gameType': 'quiz',
            'subType': 'en_vi',
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return QuizSession.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }

  static Future<ReverseQuizSession> startReverseQuizGame(
    int userId,
    int folderId,
  ) async {
    final url = Uri.parse('$_baseUrl/game/start');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'userId': userId,
            'folderId': folderId,
            'gameType': 'quiz',
            'subType': 'vi_en',
          }),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return ReverseQuizSession.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }

  static Future<String> register(String username, String password) async {
    final url = Uri.parse('$_baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return "Đăng ký thành công! Vui lòng đăng nhập.";
    } else {
      throw Exception(response.body);
    }
  }

  static Future<LoginResponse> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body);
    }
  }

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
      // Ném ra Exception với nội dung lỗi từ server
      throw Exception(response.body.replaceAll("\"", ""));
    }
  }

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

  static Future<void> deleteFolder(int folderId) async {
    final url = Uri.parse('$_baseUrl/folders/$folderId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete folder. Status code: ${response.statusCode}',
      );
    }
  }

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

  static Future<void> deleteVocabulary(int vocabularyId) async {
    final url = Uri.parse('$_baseUrl/vocabularies/$vocabularyId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete vocabulary. Server response: ${response.body}',
      );
    }
  }

  static Future<Object> startRetryGame(int gameResultId) async {
    final url = Uri.parse('$_baseUrl/game/retry-wrong');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'gameResultId': gameResultId}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      if (data.containsKey('questions') &&
          (data['questions'] as List).first.containsKey('word')) {
        return QuizSession.fromJson(data);
      } else if (data.containsKey('questions') &&
          (data['questions'] as List).first.containsKey('userDefinedMeaning')) {
        return ReverseQuizSession.fromJson(data);
      } else {
        return GameSession.fromJson(data);
      }
    } else {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }

  static Future<void> updateGameResult(
    int gameResultId,
    int correctCount,
    int wrongCount,
    List<int> wrongAnswerIds,
  ) async {
    final url = Uri.parse('$_baseUrl/game-results/$gameResultId');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'correctCount': correctCount,
        'wrongCount': wrongCount,
        'wrongAnswers': jsonEncode(wrongAnswerIds),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update game result');
    }
  }

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

  static Future<SentenceCheckResponse> checkWritingSentence(
    int vocabularyId,
    String userAnswer,
  ) async {
    final url = Uri.parse('$_baseUrl/game/check-sentence');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'vocabularyId': vocabularyId,
        'userAnswer': userAnswer,
      }),
    );

    if (response.statusCode == 200) {
      return SentenceCheckResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception('Lỗi khi kiểm tra câu. Vui lòng thử lại.');
    }
  }

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
