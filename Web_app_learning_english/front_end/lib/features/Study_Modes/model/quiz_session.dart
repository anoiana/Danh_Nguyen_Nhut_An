import '../../Vocabulary/model/vocabulary.dart';

class QuizQuestionV2 {
  final int vocabularyId;
  final String word;
  final String? phoneticText;
  final String? partOfSpeech;
  final List<String> options;
  final String correctAnswer;
  final String? userImageBase64;

  QuizQuestionV2({
    required this.vocabularyId,
    required this.word,
    this.phoneticText,
    this.partOfSpeech,
    required this.options,
    required this.correctAnswer,
    this.userImageBase64,
  });

  factory QuizQuestionV2.fromJson(Map<String, dynamic> json) {
    return QuizQuestionV2(
      vocabularyId: json['vocabularyId'] ?? 0,
      word: json['word'] ?? json['userDefinedMeaning'] ?? "Không có nội dung",
      phoneticText: json['phoneticText'],
      partOfSpeech: json['partOfSpeech'],
      options:
          (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      correctAnswer: json['correctAnswer'] ?? "",
      userImageBase64: json['userImageBase64'],
    );
  }
}

class QuizSessionV2 {
  final int gameResultId;
  final List<QuizQuestionV2> questions;

  QuizSessionV2({required this.gameResultId, required this.questions});

  factory QuizSessionV2.fromJson(Map<String, dynamic> json) {
    var questionsList = json['questions'] as List;
    List<QuizQuestionV2> questions =
        questionsList.map((i) => QuizQuestionV2.fromJson(i)).toList();
    return QuizSessionV2(
      gameResultId: json['gameResultId'],
      questions: questions,
    );
  }
}

class QuizQuestion {
  final int vocabularyId;
  final String word;
  final String? phoneticText;
  final String? partOfSpeech;
  final List<String> options;
  final String correctAnswer;
  final String? userImageBase64;

  QuizQuestion({
    required this.vocabularyId,
    required this.word,
    this.phoneticText,
    this.partOfSpeech,
    required this.options,
    required this.correctAnswer,
    this.userImageBase64,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      vocabularyId: json['vocabularyId'],
      word: json['word'],
      phoneticText: json['phoneticText'],
      partOfSpeech: json['partOfSpeech'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      userImageBase64: json['userImageBase64'],
    );
  }
}

class ReverseQuizQuestion {
  final int vocabularyId;
  final String userDefinedMeaning;
  final String? phoneticText;
  final String? partOfSpeech;
  final List<String> options;
  final String correctAnswer;
  final String? userImageBase64;

  ReverseQuizQuestion({
    required this.vocabularyId,
    required this.userDefinedMeaning,
    this.phoneticText,
    this.partOfSpeech,
    required this.options,
    required this.correctAnswer,
    this.userImageBase64,
  });

  factory ReverseQuizQuestion.fromJson(Map<String, dynamic> json) {
    return ReverseQuizQuestion(
      vocabularyId: json['vocabularyId'],
      userDefinedMeaning: json['userDefinedMeaning'],
      phoneticText: json['phoneticText'],
      partOfSpeech: json['partOfSpeech'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      userImageBase64: json['userImageBase64'],
    );
  }
}

class QuizSession {
  final int gameResultId;
  final List<QuizQuestion> questions;

  QuizSession({required this.gameResultId, required this.questions});

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    var questionsList = json['questions'] as List;
    List<QuizQuestion> questions =
        questionsList.map((i) => QuizQuestion.fromJson(i)).toList();
    return QuizSession(
      gameResultId: json['gameResultId'],
      questions: questions,
    );
  }
}

class ReverseQuizSession {
  final int gameResultId;
  final List<ReverseQuizQuestion> questions;

  ReverseQuizSession({required this.gameResultId, required this.questions});

  factory ReverseQuizSession.fromJson(Map<String, dynamic> json) {
    var questionsList = json['questions'] as List;
    List<ReverseQuizQuestion> questions =
        questionsList.map((i) => ReverseQuizQuestion.fromJson(i)).toList();
    return ReverseQuizSession(
      gameResultId: json['gameResultId'],
      questions: questions,
    );
  }
}
