import 'package:flutter/material.dart';
import '../../../core/base_view_model.dart';
import '../../../api/auth_service.dart';
import '../../../api/tts_service.dart';
import '../model/reading_content.dart';
import '../../Vocabulary/model/vocabulary.dart';

class ReadingViewModel extends BaseViewModel {
  final TextToSpeechService _ttsService = TextToSpeechService();
  TextToSpeechService get ttsService => _ttsService;

  ReadingContent? _content;
  ReadingContent? get content => _content;

  List<String> _vocabularyInFolder = [];
  List<String> get vocabularyInFolder => _vocabularyInFolder;

  int _currentQuestionIndex = 0;
  int get currentQuestionIndex => _currentQuestionIndex;

  int _score = 0;
  int get score => _score;

  bool _answered = false;
  bool get answered => _answered;

  String? _selectedOption;
  String? get selectedOption => _selectedOption;

  List<String> _paragraphs = [];
  List<String> get paragraphs => _paragraphs;

  Future<void> init({
    required int folderId,
    required int level,
    required String topic,
  }) async {
    setBusy(true);
    try {
      final vocabPage = await AuthService.getVocabulariesByFolder(
        folderId,
        page: 0,
        size: 100,
      );
      _vocabularyInFolder = vocabPage.content.map((v) => v.word).toList();

      _content = await AuthService.generateReadingGame(folderId, level, topic);
      if (_content != null) {
        _paragraphs = _splitTextIntoParagraphs(_content!.story);
      }
      _ttsService.init();
      _resetGameState();
      setBusy(false);
    } catch (e) {
      debugPrint('Error initializing Reading Game: $e');
      setError(e.toString());
      setBusy(false);
    }
  }

  void _resetGameState() {
    _currentQuestionIndex = 0;
    _score = 0;
    _answered = false;
    _selectedOption = null;
  }

  void checkAnswer(String option) {
    if (_answered || _content == null) return;

    _selectedOption = option;
    _answered = true;
    if (option == _content!.questions[_currentQuestionIndex].answer) {
      _score++;
    }
    notifyListeners();
  }

  bool nextQuestion() {
    if (_content != null &&
        _currentQuestionIndex < _content!.questions.length - 1) {
      _currentQuestionIndex++;
      _answered = false;
      _selectedOption = null;
      notifyListeners();
      return true;
    }
    return false; // Game finished
  }

  void stopTTS() {
    _ttsService.stop();
  }

  void speak(String text) {
    _ttsService.stop().then((_) {
      _ttsService.setSpeechRate(0.5);
      _ttsService.speak(text);
    });
  }

  List<String> _splitTextIntoParagraphs(
    String text, {
    int sentencesPerParagraph = 3,
  }) {
    if (text.isEmpty) return [];
    final List<String> sentences = text.split(RegExp(r'(?<=[.?!])\s+'));
    if (sentences.length <= sentencesPerParagraph) return [text];
    final List<String> paragraphs = [];
    for (var i = 0; i < sentences.length; i += sentencesPerParagraph) {
      var end =
          (i + sentencesPerParagraph < sentences.length)
              ? i + sentencesPerParagraph
              : sentences.length;
      paragraphs.add(sentences.sublist(i, end).join(' ').trim());
    }
    return paragraphs.where((p) => p.isNotEmpty).toList();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }
}
