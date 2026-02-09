import '../../Vocabulary/model/vocabulary.dart';

class GameSession {
  final int gameResultId;
  final List<Vocabulary> vocabularies;

  GameSession({required this.gameResultId, required this.vocabularies});

  factory GameSession.fromJson(Map<String, dynamic> json) {
    var vocabList = json['vocabularies'] as List? ?? [];
    List<Vocabulary> vocabularies =
        vocabList.map((i) => Vocabulary.fromJson(i)).toList();
    return GameSession(
      gameResultId: json['gameResultId'] ?? 0,
      vocabularies: vocabularies,
    );
  }
}
