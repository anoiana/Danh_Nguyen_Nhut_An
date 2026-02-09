import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/app_constants.dart';
import '../model/game_session.dart';
import '../model/quiz_session.dart';
import '../model/sentence_check_response.dart';
import '../model/reading_content.dart';
import '../model/listening_content.dart';

/// Service for study mode game-related API calls
class StudyModeService {
  static const String _baseUrl = AppConstants.baseUrl;

  /// Start a generic game (flashcard, writing, etc.)
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

  /// Start a quiz game
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

  /// Start a quiz game with subType parameter (returns QuizSessionV2)
  static Future<QuizSessionV2> startQuizGameV2(
    int userId,
    int folderId, {
    String subType = 'en_vi',
  }) async {
    final url = Uri.parse('$_baseUrl/game/start');
    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode({
            'userId': userId,
            'folderId': folderId,
            'gameType': 'quiz',
            'subType': subType,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return QuizSessionV2.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }

  /// Start a reverse quiz game (Vietnamese to English)
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

  /// Retry wrong answers from a previous game
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

  /// Update game result after finishing
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

  /// Generate listening game content using AI
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
            'gameSubType': gameSubType,
          }),
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) {
      return ListeningContent.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)),
      );
    } else {
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

  /// Generate reading game content using AI
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
            'topic': topic,
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

  /// Check a writing sentence for grammar
  static Future<SentenceCheckResponse> checkWritingSentence(
    int vocabularyId,
    String userAnswer,
  ) async {
    final url = Uri.parse('$_baseUrl/game/check-sentence');
    debugPrint('[SentenceGame] 🔵 REQUEST: POST $url');
    debugPrint(
      '[SentenceGame] 📤 BODY: {vocabularyId: $vocabularyId, userAnswer: $userAnswer}',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'vocabularyId': vocabularyId,
          'userAnswer': userAnswer,
        }),
      );

      debugPrint('[SentenceGame] 📊 STATUS: ${response.statusCode}');
      debugPrint(
        '[SentenceGame] 📦 RESPONSE: ${utf8.decode(response.bodyBytes)}',
      );

      if (response.statusCode == 200) {
        return SentenceCheckResponse.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)),
        );
      } else {
        debugPrint(
          '[SentenceGame] ❌ ERROR: ${utf8.decode(response.bodyBytes)}',
        );
        throw Exception('Lỗi khi kiểm tra câu. Vui lòng thử lại.');
      }
    } catch (e) {
      debugPrint('[SentenceGame] ❌ CONNECTION ERROR: $e');
      rethrow;
    }
  }
}
