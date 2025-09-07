import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginResponse {
  final String message;
  final int userId;
  final String username;

  LoginResponse({required this.message, required this.userId, required this.username});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'],
      userId: json['userId'],
      username: json['username'], // Đọc username từ JSON
    );
  }
}

class SentenceCheckResponse {
  final bool isCorrect;
  final String feedback;

  SentenceCheckResponse({required this.isCorrect, required this.feedback});

  factory SentenceCheckResponse.fromJson(Map<String, dynamic> json) {
    return SentenceCheckResponse(
      isCorrect: json['isCorrect'],
      feedback: json['feedback'],
    );
  }
}

class Folder {
  final int id;
  final String name;
  final int userId;
  final int vocabularyCount;

  Folder({required this.id, required this.name, required this.userId, required this.vocabularyCount});

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'],
      name: json['name'],
      userId: json['userId'],
      vocabularyCount: json['vocabularyCount'] ?? 0,
    );
  }
}

class DictionaryEntry {
  final String word;
  final String? phonetic;
  final String? audioUrl;
  final List<Meaning> meanings;

  DictionaryEntry({required this.word, this.phonetic, this.audioUrl, required this.meanings});

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    String? audio = '';
    if (json['phonetics'] != null && (json['phonetics'] as List).isNotEmpty) {
      final phoneticsList = json['phonetics'] as List;
      final audioItem = phoneticsList.firstWhere((p) => p['audio'] != null && p['audio'] != '', orElse: () => null);
      if (audioItem != null) {
        audio = audioItem['audio'];
      }
    }

    return DictionaryEntry(
      word: json['word'],
      phonetic: json['phonetic'],
      audioUrl: audio,
      meanings: (json['meanings'] as List).map((m) => Meaning.fromJson(m)).toList(),
    );
  }
}

class Meaning {
  final String partOfSpeech;
  final List<Definition> definitions;
  final List<String> synonyms;
  final List<String> antonyms;

  Meaning({
    required this.partOfSpeech,
    required this.definitions,
    required this.synonyms,
    required this.antonyms,
  });

  factory Meaning.fromJson(Map<String, dynamic> json) {
    return Meaning(
      partOfSpeech: json['partOfSpeech'],
      definitions: (json['definitions'] as List).map((d) => Definition.fromJson(d)).toList(),
      synonyms: List<String>.from(json['synonyms'] ?? []),
      antonyms: List<String>.from(json['antonyms'] ?? []),
    );
  }
}

class Definition {
  final String definition;
  final String? example;

  Definition({required this.definition, this.example});

  factory Definition.fromJson(Map<String, dynamic> json) {
    return Definition(
      definition: json['definition'],
      example: json['example'],
    );
  }
}

class Vocabulary {
  final int id;
  final String word;
  final String? phoneticText;
  final String? audioUrl;
  final String? userDefinedMeaning;
  final String? userDefinedPartOfSpeech; // <-- THÊM TRƯỜNG MỚI
  final String? userImageBase64;
  final List<Meaning>? meanings;
  final Alignment? imageAlignment;

  Vocabulary({
    required this.id,
    required this.word,
    this.phoneticText,
    this.audioUrl,
    this.userDefinedMeaning,
    this.userDefinedPartOfSpeech, // <-- THÊM VÀO CONSTRUCTOR
    this.userImageBase64,
    this.meanings,
    this.imageAlignment,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    var meaningsList = json['meanings'] as List?;
    List<Meaning>? meanings = meaningsList?.map((m) => Meaning.fromJson(m)).toList();

    final double? alignX = (json['image_alignment_x'] as num?)?.toDouble();
    final double? alignY = (json['image_alignment_y'] as num?)?.toDouble();
    final Alignment? alignment = (alignX != null && alignY != null)
        ? Alignment(alignX, alignY)
        : null;

    return Vocabulary(
      id: json['id'],
      word: json['word'],
      phoneticText: json['phoneticText'],
      audioUrl: json['audioUrl'],
      userDefinedMeaning: json['userDefinedMeaning'],
      userDefinedPartOfSpeech: json['userDefinedPartOfSpeech'], // <-- ĐỌC TỪ JSON
      userImageBase64: json['userImageBase64'],
      meanings: meanings,
      imageAlignment: alignment,
    );
  }
}

class FolderPage {
  final List<Folder> content;
  final int totalPages;
  final bool isLast;

  FolderPage({required this.content, required this.totalPages, required this.isLast});

  factory FolderPage.fromJson(Map<String, dynamic> json) {
    var list = json['content'] as List;
    List<Folder> folderList = list.map((i) => Folder.fromJson(i)).toList();
    return FolderPage(
      content: folderList,
      totalPages: json['totalPages'],
      isLast: json['last'],
    );
  }
}

class VocabularyPage {
  final List<Vocabulary> content;
  final int totalPages;
  final bool isLast;

  VocabularyPage({required this.content, required this.totalPages, required this.isLast});

  factory VocabularyPage.fromJson(Map<String, dynamic> json) {
    var list = json['content'] as List;
    List<Vocabulary> vocabList = list.map((i) => Vocabulary.fromJson(i)).toList();
    return VocabularyPage(
      content: vocabList,
      totalPages: json['totalPages'],
      isLast: json['last'],
    );
  }
}

class VocabularySimpleDTO {
  final int id;
  final String word;
  final String? phoneticText;
  final String? userDefinedMeaning;
  final String? userImageBase64;
  final String? audioUrl;

  VocabularySimpleDTO({
    required this.id,
    required this.word,
    this.phoneticText,
    this.userDefinedMeaning,
    this.userImageBase64,
    this.audioUrl,
  });

  factory VocabularySimpleDTO.fromJson(Map<String, dynamic> json) {
    return VocabularySimpleDTO(
      id: json['id'],
      word: json['word'],
      phoneticText: json['phoneticText'],
      userDefinedMeaning: json['userDefinedMeaning'],
      userImageBase64: json['userImageBase64'],
      audioUrl: json['audioUrl'],
    );
  }
}

class GameSession {
  final int gameResultId;
  final List<Vocabulary> vocabularies;

  GameSession({required this.gameResultId, required this.vocabularies});

  factory GameSession.fromJson(Map<String, dynamic> json) {
    var vocabList = json['vocabularies'] as List? ?? [];
    List<Vocabulary> vocabularies = vocabList.map((i) => Vocabulary.fromJson(i)).toList();
    return GameSession(
      gameResultId: json['gameResultId'] ?? 0,
      vocabularies: vocabularies,
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
    List<QuizQuestion> questions = questionsList.map((i) => QuizQuestion.fromJson(i)).toList();
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
    List<ReverseQuizQuestion> questions = questionsList.map((i) => ReverseQuizQuestion.fromJson(i)).toList();
    return ReverseQuizSession(
      gameResultId: json['gameResultId'],
      questions: questions,
    );
  }
}

class ReadingContent {
  final String story;
  final List<ReadingQuestion> questions;

  ReadingContent({required this.story, required this.questions});

  factory ReadingContent.fromJson(Map<String, dynamic> json) {
    var questionsList = json['questions'] as List? ?? []; // Đảm bảo an toàn nếu 'questions' là null
    List<ReadingQuestion> questions = questionsList
        .map((i) => ReadingQuestion.fromJson(i))
        .toList();

    return ReadingContent(
      // <<< THÊM TOÁN TỬ ?? '' ĐỂ CUNG CẤP GIÁ TRỊ MẶC ĐỊNH >>>
      story: json['story'] ?? 'Không có nội dung bài đọc.',
      questions: questions,
    );
  }
}

class ReadingQuestion {
  final String question;
  final List<String> options;
  final String answer;

  ReadingQuestion({required this.question, required this.options, required this.answer});

  // Trong file lib/api/auth_service.dart

  factory ReadingQuestion.fromJson(Map<String, dynamic> json) {
    // 1. Xử lý an toàn cho danh sách options
    // Lấy danh sách dưới dạng List<dynamic> để chấp nhận mọi kiểu dữ liệu
    final optionsList = json['options'] as List? ?? [];

    // Dùng map() và toString() để chuyển đổi TẤT CẢ các phần tử thành String
    final List<String> safeOptions = optionsList.map((option) => option.toString()).toList();

    // 2. Xử lý an toàn cho đáp án
    // Dùng ?.toString() để chuyển đổi an toàn, kể cả khi giá trị là null
    final String safeAnswer = json['answer']?.toString() ?? '';

    return ReadingQuestion(
      question: json['question'] ?? 'Câu hỏi không có nội dung.',
      options: safeOptions, // Sử dụng danh sách đã được làm sạch
      answer: safeAnswer,   // Sử dụng đáp án đã được làm sạch
    );
  }
}

class ListeningContent {
  final String transcript;
  final List<ListeningMCQ> mcq;
  final ListeningFITB fitb;

  ListeningContent({
    required this.transcript,
    required this.mcq,
    required this.fitb,
  });

  factory ListeningContent.fromJson(Map<String, dynamic> json) {
    var mcqList = json['mcq'] as List? ?? [];
    List<ListeningMCQ> mcqs = mcqList.map((i) => ListeningMCQ.fromJson(i)).toList();

    return ListeningContent(
      transcript: json['transcript'] ?? 'Không có nội dung.',
      mcq: mcqs,
      fitb: ListeningFITB.fromJson(json['fitb'] ?? {}),
    );
  }
}

class ListeningMCQ {
  final String question;
  final List<String> options;
  final String answer;

  ListeningMCQ({required this.question, required this.options, required this.answer});

  factory ListeningMCQ.fromJson(Map<String, dynamic> json) {
    return ListeningMCQ(
      question: json['question'] ?? 'Câu hỏi không có nội dung.',
      options: List<String>.from(json['options'] ?? []),
      answer: json['answer'] ?? '',
    );
  }
}

class ListeningFITB {
  final String textWithBlanks;
  final List<String> answers;

  ListeningFITB({required this.textWithBlanks, required this.answers});

  factory ListeningFITB.fromJson(Map<String, dynamic> json) {
    return ListeningFITB(
      textWithBlanks: json['textWithBlanks'] ?? '',
      answers: List<String>.from(json['answers'] ?? []),
    );
  }
}

class AuthService {

  static const String _baseUrl = "http://localhost:8080/api";

  // static const String _baseUrl = "https://5e6c5e02d0b3.ngrok-free.app/api";

  static Future<ListeningContent> generateListeningGame(
      int folderId,
      int level,
      String topic,
      String gameSubType, // <<< THAM SỐ MỚI
      ) async {
    final url = Uri.parse('$_baseUrl/game/generate-listening');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'folderId': folderId,
        'level': level,
        'topic': topic,
        'gameSubType': gameSubType, // <<< GỬI THÊM THAM SỐ NÀY LÊN SERVER
      }),
    ).timeout(const Duration(seconds: 90)); // Tăng timeout cho AI

    if (response.statusCode == 200) {
      return ListeningContent.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      // Cố gắng decode lỗi từ server để hiển thị cho người dùng
      try {
        String errorMessage = utf8.decode(response.bodyBytes).replaceAll("\"", "");
        throw Exception(errorMessage);
      } catch (_) {
        throw Exception('Failed to generate listening content: ${response.body}');
      }
    }
  }

  static Future<String> translateWord(String word) async {
    final url = Uri.parse('$_baseUrl/translate/$word');
    try {
      final response = await http.get(url)
          .timeout(const Duration(seconds: 10));

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

  static Future<ReadingContent> generateReadingGame(int folderId, int level, String topic) async {
    final url = Uri.parse('$_baseUrl/game/generate-reading');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'folderId': folderId,
        'level': level,
        'topic': topic, // <<< THÊM TOPIC VÀO PAYLOAD
      }),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      return ReadingContent.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
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
      'meanings': entry.meanings.map((m) => {
        'partOfSpeech': m.partOfSpeech,
        'synonyms': m.synonyms,
        'antonyms': m.antonyms,
        'definitions': m.definitions.map((d) => {
          'definition': d.definition,
          'example': d.example,
        }).toList(),
      }).toList(),
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
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
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
  static Future<void> updateVocabularyImage(int vocabularyId, String imageUrl) async {
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

  static Future<GameSession> startGenericGame(int userId, int folderId, String gameType) async {
    final url = Uri.parse('$_baseUrl/game/start');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'userId': userId, 'folderId': folderId, 'gameType': gameType}),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return GameSession.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }

  static Future<QuizSession> startQuizGame(int userId, int folderId) async {
    final url = Uri.parse('$_baseUrl/game/start');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'userId': userId, 'folderId': folderId, 'gameType': 'quiz', 'subType': 'en_vi'}),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return QuizSession.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }

  static Future<ReverseQuizSession> startReverseQuizGame(int userId, int folderId) async {
    final url = Uri.parse('$_baseUrl/game/start');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'userId': userId, 'folderId': folderId, 'gameType': 'quiz', 'subType': 'vi_en'}),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return ReverseQuizSession.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
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

  static Future<FolderPage> getFoldersByUser(int userId, {int page = 0, int size = 15, String search = ''}) async {
    final url = Uri.parse('$_baseUrl/folders/user/$userId?page=$page&size=$size&search=$search');
    final response = await http.get(url, headers: {'Content-Type': 'application/json; charset=UTF-8'});

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
      throw Exception('Failed to update folder. Status code: ${response.statusCode}');
    }
  }

  static Future<void> deleteFolder(int folderId) async {
    final url = Uri.parse('$_baseUrl/folders/$folderId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete folder. Status code: ${response.statusCode}');
    }
  }

  static Future<VocabularyPage> getVocabulariesByFolder(int folderId, {int page = 0, int size = 15, String search = ''}) async {
    final url = Uri.parse('$_baseUrl/vocabularies/folder/$folderId?page=$page&size=$size&search=$search');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return VocabularyPage.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load vocabularies for folder $folderId');
    }
  }

  static Future<void> deleteVocabulary(int vocabularyId) async {
    final url = Uri.parse('$_baseUrl/vocabularies/$vocabularyId');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete vocabulary. Server response: ${response.body}');
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
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data.containsKey('questions') && (data['questions'] as List).first.containsKey('word')) {
        return QuizSession.fromJson(data);
      } else if (data.containsKey('questions') && (data['questions'] as List).first.containsKey('userDefinedMeaning')) {
        return ReverseQuizSession.fromJson(data);
      } else {
        return GameSession.fromJson(data);
      }
    } else {
      throw Exception(utf8.decode(response.bodyBytes));
    }
  }

  static Future<void> updateGameResult(int gameResultId, int correctCount, int wrongCount, List<int> wrongAnswerIds) async {
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
    final url = Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word');
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

  static Future<SentenceCheckResponse> checkWritingSentence(int vocabularyId, String userAnswer) async {
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
      return SentenceCheckResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
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

  static Future<void> moveVocabularies(List<int> vocabularyIds, int targetFolderId) async {
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