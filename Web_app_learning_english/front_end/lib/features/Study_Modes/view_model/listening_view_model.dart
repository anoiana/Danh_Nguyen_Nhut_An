import 'dart:async';
import 'package:flutter/material.dart';
import '../../../api/auth_service.dart';
import '../../../api/tts_service.dart';
import '../../../api/sound_service.dart';
import '../service/study_mode_service.dart';
import '../model/game_session.dart';
import '../model/listening_content.dart';
import '../../Vocabulary/model/vocabulary.dart';

enum ListeningGameType { vocabulary, ai }

enum FeedbackState { initial, correct, incorrect, loading }

class ListeningViewModel extends ChangeNotifier {
  final StudyModeService _service = StudyModeService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final SoundService _soundService = SoundService();

  TextToSpeechService get ttsService => _ttsService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ListeningGameType? _gameType;
  ListeningGameType? get gameType => _gameType;

  // AI Game State
  ListeningContent? _aiContent;
  ListeningContent? get aiContent => _aiContent;
  String? _aiSubType;
  String? get aiSubType => _aiSubType;
  bool _isSubmitted = false;
  bool get isSubmitted => _isSubmitted;
  List<String?> _selectedMcqOptions = [];
  List<String?> get selectedMcqOptions => _selectedMcqOptions;
  List<bool?> _mcqResults = [];
  List<bool?> get mcqResults => _mcqResults;
  int _mcqScore = 0;
  int get mcqScore => _mcqScore;
  List<TextEditingController> _fitbControllers = [];
  List<TextEditingController> get fitbControllers => _fitbControllers;
  List<bool?> _fitbResults = [];
  List<bool?> get fitbResults => _fitbResults;
  int _fitbScore = 0;
  int get fitbScore => _fitbScore;
  double _playbackProgress = 0.0;
  double get playbackProgress => _playbackProgress;
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // Vocabulary Game State
  GameSession? _vocabSession;
  GameSession? get vocabSession => _vocabSession;
  int _currentVocabIndex = 0;
  int get currentVocabIndex => _currentVocabIndex;
  int _correctCount = 0;
  int get correctCount => _correctCount;
  int _wrongCount = 0;
  int get wrongCount => _wrongCount;
  FeedbackState _feedbackState = FeedbackState.initial;
  FeedbackState get feedbackState => _feedbackState;
  final List<int> _wrongAnswerVocabIds = [];
  final List<Vocabulary> _wrongVocabularies = [];
  List<Vocabulary> get wrongVocabularies => _wrongVocabularies;

  late StreamSubscription<bool> _isPlayingSubscription;
  late StreamSubscription<double> _progressSubscription;

  void init() {
    _ttsService.init();
    _isPlayingSubscription = _ttsService.isPlayingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });
    _progressSubscription = _ttsService.progressStream.listen((progress) {
      _playbackProgress = progress;
      notifyListeners();
    });
  }

  Future<void> startVocabListening(int userId, int folderId) async {
    _isLoading = true;
    _gameType = ListeningGameType.vocabulary;
    notifyListeners();

    try {
      final session = await _service.startGenericGame(
        userId,
        folderId,
        'listening',
      );
      _vocabSession = session;
      _resetVocabState();
    } catch (e) {
      debugPrint('Error starting Vocab Listening: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startAIListening(
    int folderId,
    int level,
    String topic,
    String subType,
  ) async {
    _isLoading = true;
    _gameType = ListeningGameType.ai;
    _aiSubType = subType;
    notifyListeners();

    try {
      _aiContent = await AuthService.generateListeningGame(
        folderId,
        level,
        topic,
        subType,
      );
      if (_aiContent != null) {
        _resetAIState();
      }
    } catch (e) {
      debugPrint('Error starting AI Listening: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetVocabState() {
    _currentVocabIndex = 0;
    _correctCount = 0;
    _wrongCount = 0;
    _feedbackState = FeedbackState.initial;
    _isSubmitted = false;
    _wrongAnswerVocabIds.clear();
  }

  void _resetAIState() {
    _isSubmitted = false;
    _mcqScore = 0;
    _fitbScore = 0;
    _playbackProgress = 0.0;
    final content = _aiContent;
    if (content != null) {
      _selectedMcqOptions = List.filled(content.mcq.length, null);
      _mcqResults = List.filled(content.mcq.length, null);
      final fitb = content.fitb;
      _fitbControllers = List.generate(
        fitb.answers.length,
        (_) => TextEditingController(),
      );
      _fitbResults = List.filled(fitb.answers.length, null);
    }
  }

  // --- Vocabulary Game Actions ---
  void speakCurrentVocab() {
    final session = _vocabSession;
    if (session != null) {
      _ttsService.speak(session.vocabularies[_currentVocabIndex].word);
    }
  }

  Future<void> checkVocabAnswer(String answer) async {
    final session = _vocabSession;
    if (_isSubmitted || session == null) return;
    final currentVocab = session.vocabularies[_currentVocabIndex];
    final isCorrect =
        answer.trim().toLowerCase() == currentVocab.word.trim().toLowerCase();

    _isSubmitted = true;
    if (isCorrect) {
      _correctCount++;
      _feedbackState = FeedbackState.correct;
      notifyListeners();
      await _soundService.playCorrectAndWait();
    } else {
      _wrongCount++;
      _wrongAnswerVocabIds.add(currentVocab.id);
      _wrongVocabularies.add(currentVocab);
      _feedbackState = FeedbackState.incorrect;
      notifyListeners();
      await _soundService.playWrongAndWait();
    }
  }

  void startWrongWordsRetry() {
    if (_wrongVocabularies.isEmpty) return;
    final retryVocabs = List<Vocabulary>.from(_wrongVocabularies);
    if (_vocabSession != null) {
      _vocabSession = GameSession(
        gameResultId: _vocabSession!.gameResultId,
        vocabularies: retryVocabs,
      );
    }
    _wrongVocabularies.clear();
    _resetVocabState();
  }

  void nextVocabWord() {
    final session = _vocabSession;
    if (session == null) return;
    if (_currentVocabIndex < session.vocabularies.length - 1) {
      _currentVocabIndex++;
      _isSubmitted = false;
      _feedbackState = FeedbackState.initial;
      notifyListeners();
      speakCurrentVocab();
    } else {
      _finishVocabGame();
    }
  }

  Future<void> submitVocabResult() async {
    await _finishVocabGame();
  }

  Future<void> _finishVocabGame() async {
    final session = _vocabSession;
    if (session == null) return;
    try {
      await AuthService.updateGameResult(
        session.gameResultId,
        _correctCount,
        _wrongCount,
        _wrongAnswerVocabIds,
      );
    } catch (e) {
      debugPrint("Error updating game result: $e");
    }
    notifyListeners();
  }

  Future<void> retryVocabGame(int userId, int folderId) async {
    await startVocabListening(userId, folderId);
  }

  // --- AI Game Actions ---
  void togglePlayPause() {
    final content = _aiContent;
    if (_isPlaying) {
      _ttsService.stop();
    } else if (content != null) {
      if (_playbackProgress >= 1.0) _playbackProgress = 0.0;
      _ttsService.speak(content.transcript);
    }
  }

  void replay() {
    _ttsService.stop();
    Future.delayed(const Duration(milliseconds: 100), () {
      _playbackProgress = 0;
      final content = _aiContent;
      if (content != null) _ttsService.speak(content.transcript);
    });
  }

  void onMcqOptionSelected(int index, String option) {
    if (_isSubmitted) return;
    _selectedMcqOptions[index] = option;
    notifyListeners();
  }

  void checkAIAnswers() {
    final content = _aiContent;
    if (content == null) return;
    if (_aiSubType == 'mcq') {
      int correct = 0;
      for (int i = 0; i < content.mcq.length; i++) {
        bool isCorrect = _selectedMcqOptions[i] == content.mcq[i].answer;
        if (isCorrect) correct++;
        _mcqResults[i] = isCorrect;
      }
      _mcqScore = correct;
    } else if (_aiSubType == 'fitb' && content.fitb != null) {
      int correct = 0;
      for (int i = 0; i < _fitbControllers.length; i++) {
        bool isCorrect =
            _fitbControllers[i].text.trim().toLowerCase() ==
            content.fitb.answers[i].toLowerCase();
        if (isCorrect) correct++;
        _fitbResults[i] = isCorrect;
      }
      _fitbScore = correct;
    }
    _isSubmitted = true;
    notifyListeners();
  }

  void resetAIGame() {
    _resetAIState();
    notifyListeners();
  }

  void speak(String text) {
    _ttsService.stop().then((_) {
      _ttsService.setSpeechRate(0.5);
      _ttsService.speak(text);
    });
  }

  @override
  void dispose() {
    _isPlayingSubscription.cancel();
    _progressSubscription.cancel();
    _ttsService.stop();
    for (var controller in _fitbControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
