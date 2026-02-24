// lib/features/Study_Modes/view_model/speaking_view_model.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../api/tts_service.dart';
import '../../../api/stt_service.dart';
import '../../../api/sound_service.dart';
import '../service/study_mode_service.dart';
import '../model/game_session.dart';
import '../../Vocabulary/model/vocabulary.dart';

enum SpeakingFeedbackState { initial, listening, correct, incorrect, skipped }

class SpeakingViewModel extends ChangeNotifier {
  final TextToSpeechService _ttsService = TextToSpeechService();
  final SpeechToTextService _sttService = SpeechToTextService();
  final SoundService _soundService = SoundService();

  // Getters for services
  TextToSpeechService get ttsService => _ttsService;
  SpeechToTextService get sttService => _sttService;

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Submitting result state
  bool _isSubmittingResult = false;
  bool get isSubmittingResult => _isSubmittingResult;

  // Game session
  GameSession? _session;
  GameSession? get session => _session;

  // Current word index
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  // Score tracking
  int _correctCount = 0;
  int get correctCount => _correctCount;

  int _wrongCount = 0;
  int get wrongCount => _wrongCount;

  int _skippedCount = 0;
  int get skippedCount => _skippedCount;

  // Feedback state
  SpeakingFeedbackState _feedbackState = SpeakingFeedbackState.initial;
  SpeakingFeedbackState get feedbackState => _feedbackState;

  // Recognized text
  String _recognizedText = '';
  String get recognizedText => _recognizedText;

  // STT Status
  SttStatus _sttStatus = SttStatus.idle;
  SttStatus get sttStatus => _sttStatus;

  // Sound level for microphone animation
  double _soundLevel = 0.0;
  double get soundLevel => _soundLevel;

  // Is word revealed (hint)
  bool _isWordRevealed = false;
  bool get isWordRevealed => _isWordRevealed;

  // Wrong answer tracking for retry
  final List<int> _wrongAnswerVocabIds = [];
  final List<Vocabulary> _wrongVocabularies = [];
  List<Vocabulary> get wrongVocabularies => _wrongVocabularies;

  // Stream subscriptions
  StreamSubscription<SttStatus>? _statusSubscription;
  StreamSubscription<String>? _textSubscription;
  StreamSubscription<double>? _soundSubscription;

  /// Initialize the view model
  Future<void> init() async {
    await _ttsService.init();
    await _sttService.init();

    // Listen to STT status changes
    _statusSubscription = _sttService.statusStream.listen((status) {
      debugPrint('STT Status Changed: $status');
      _sttStatus = status;
      if (status == SttStatus.listening) {
        _feedbackState = SpeakingFeedbackState.listening;
      } else if (status == SttStatus.processing) {
        if (_recognizedText.isNotEmpty) {
          debugPrint('STT Processing Final Result: $_recognizedText');
          _checkAnswer(_recognizedText);
        }
      }
      notifyListeners();
    });

    // Listen to recognized text changes
    _textSubscription = _sttService.recognizedTextStream.listen((text) {
      debugPrint('STT Recognized: $text (Status: $_sttStatus)');
      _recognizedText = text;
      notifyListeners();

      // Auto-check when we get a final result
      // Note: Status logic is handled in status listener primarily now but we keep this just in case
      if (_sttStatus == SttStatus.processing && text.isNotEmpty) {
        _checkAnswer(text);
      }
    });

    // Listen to sound level for animation
    _soundSubscription = _sttService.soundLevelStream.listen((level) {
      _soundLevel = level;
      notifyListeners();
    });
  }

  /// Start the speaking game
  Future<void> startGame(int userId, int folderId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final gameSession = await StudyModeService.startGenericGame(
        userId,
        folderId,
        'flashcard',
      );
      _session = gameSession;
      _resetState();

      // Auto-play the first word after a short delay
      await Future.delayed(const Duration(milliseconds: 500));
      _speakCurrentWord();
    } catch (e) {
      debugPrint('Error starting Speaking game: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset state for new game
  void _resetState() {
    _currentIndex = 0;
    _correctCount = 0;
    _wrongCount = 0;
    _skippedCount = 0;
    _feedbackState = SpeakingFeedbackState.initial;
    _recognizedText = '';
    _isWordRevealed = false;
    _wrongAnswerVocabIds.clear();
    _wrongVocabularies.clear();
  }

  /// Get current vocabulary
  Vocabulary? get currentVocabulary {
    if (_session == null || _currentIndex >= _session!.vocabularies.length) {
      return null;
    }
    return _session!.vocabularies[_currentIndex];
  }

  /// Get total words count
  int get totalWords => _session?.vocabularies.length ?? 0;

  /// Check if game is finished
  bool get isFinished =>
      _session != null && _currentIndex >= _session!.vocabularies.length;

  /// Speak the current word
  void _speakCurrentWord() {
    final vocab = currentVocabulary;
    if (vocab != null) {
      _ttsService.speak(vocab.word);
    }
  }

  /// Replay current word
  void replayWord() {
    _speakCurrentWord();
  }

  /// Start listening for user speech
  Future<void> startListening() async {
    if (_sttStatus == SttStatus.listening) {
      await _sttService.stopListening();
      return;
    }

    _recognizedText = '';
    _feedbackState = SpeakingFeedbackState.listening;
    notifyListeners();

    await _sttService.startListening(
      localeId: 'en-US',
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _sttService.stopListening();
  }

  /// Check the user's answer
  Future<void> _checkAnswer(String spokenText) async {
    // Prevent double checking or checking after feedback is given
    if (_feedbackState != SpeakingFeedbackState.listening &&
        _feedbackState != SpeakingFeedbackState.initial) {
      return;
    }

    final vocab = currentVocabulary;
    if (vocab == null) return;

    debugPrint('Checking Answer: "$spokenText" for word: "${vocab.word}"');

    final isCorrect = SpeechToTextService.compareWords(spokenText, vocab.word);

    if (isCorrect) {
      _correctCount++;
      _feedbackState = SpeakingFeedbackState.correct;
      notifyListeners();
      _soundService.playCorrect();
    } else {
      _wrongCount++;
      _wrongAnswerVocabIds.add(vocab.id);
      _wrongVocabularies.add(vocab);
      _feedbackState = SpeakingFeedbackState.incorrect;
      notifyListeners();
      _soundService.playWrong();
    }
  }

  /// Show hint (reveal the word)
  void showHint() {
    _isWordRevealed = true;
    notifyListeners();
  }

  /// Skip current word
  Future<void> skipWord() async {
    final vocab = currentVocabulary;
    if (vocab != null) {
      _skippedCount++;
      _wrongAnswerVocabIds.add(vocab.id);
      _wrongVocabularies.add(vocab);
      _feedbackState = SpeakingFeedbackState.skipped;
      notifyListeners();
    }
  }

  /// Move to next word
  Future<void> nextWord() async {
    if (_session == null) return;

    if (_currentIndex < _session!.vocabularies.length - 1) {
      _currentIndex++;
      _feedbackState = SpeakingFeedbackState.initial;
      _recognizedText = '';
      _isWordRevealed = false;
      notifyListeners();

      // Auto-play the next word
      await Future.delayed(const Duration(milliseconds: 300));
      _speakCurrentWord();
    } else {
      // Game finished
      _currentIndex++;
      _isSubmittingResult = true;
      notifyListeners();
      await _finishGame();
      _isSubmittingResult = false;
      notifyListeners();
    }
  }

  /// Retry with wrong words only
  void startWrongWordsRetry() {
    if (_wrongVocabularies.isEmpty) return;

    final retryVocabs = List<Vocabulary>.from(_wrongVocabularies);
    if (_session != null) {
      _session = GameSession(
        gameResultId: _session!.gameResultId,
        vocabularies: retryVocabs,
      );
    }
    _resetState();
    notifyListeners();

    // Auto-play the first word
    Future.delayed(const Duration(milliseconds: 500), () {
      _speakCurrentWord();
    });
  }

  /// Finish the game
  Future<void> _finishGame() async {
    if (_session == null) return;

    try {
      await StudyModeService.updateGameResult(
        _session!.gameResultId,
        _correctCount,
        _wrongCount + _skippedCount,
        _wrongAnswerVocabIds,
      );
    } catch (e) {
      debugPrint('Error updating game result: $e');
    }
    notifyListeners();
  }

  /// Retry the entire game
  Future<void> retryGame(int userId, int folderId) async {
    await startGame(userId, folderId);
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _textSubscription?.cancel();
    _soundSubscription?.cancel();
    _sttService.cancel();
    _ttsService.stop();
    super.dispose();
  }
}
