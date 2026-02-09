import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/app_constants.dart';
import '../model/game_session.dart';
import '../model/quiz_session.dart';

class StudyModeService {
  final http.Client _client = http.Client();

  Future<GameSession> startGenericGame(
    int userId,
    int folderId,
    String gameType,
  ) async {
    final url = Uri.parse('${AppConstants.baseUrl}/game/start');
    final response = await _client
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

  // Future: Add other game start methods here (Quiz, Listening, etc.)
  Future<QuizSessionV2> startQuizGame(
    int userId,
    int folderId, {
    String subType = 'en_vi',
  }) async {
    final url = Uri.parse('${AppConstants.baseUrl}/game/start');
    final response = await _client
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
}
