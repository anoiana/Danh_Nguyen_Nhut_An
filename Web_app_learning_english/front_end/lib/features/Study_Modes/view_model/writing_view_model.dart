import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/base_view_model.dart';
import '../../Vocabulary/model/vocabulary.dart';
import '../model/game_session.dart';
import '../service/study_mode_service.dart';
import '../../../api/sound_service.dart';

enum FeedbackState { initial, correct, incorrect }

class WritingViewModel extends BaseViewModel {
  final SoundService _soundService = SoundService();

  GameSession? _session;
  List<Vocabulary> get vocabularies => _session?.vocabularies ?? [];

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  int _correctCount = 0;
  int get correctCount => _correctCount;

  int _wrongCount = 0;
  int get wrongCount => _wrongCount;

  List<int> _wrongAnswerVocabIds = [];

  bool _isSubmitted = false;
  bool get isSubmitted => _isSubmitted;

  FeedbackState _feedbackState = FeedbackState.initial;
  FeedbackState get feedbackState => _feedbackState;

  Vocabulary? get currentVocabulary =>
      vocabularies.isNotEmpty && _currentIndex < vocabularies.length
          ? vocabularies[_currentIndex]
          : null;

  bool get isFinished => _currentIndex >= vocabularies.length;

  Future<void> init(int userId, int folderId) async {
    setBusy(true);
    try {
      _session = await StudyModeService.startGenericGame(
        userId,
        folderId,
        'writing',
      );
      _resetState();
      setBusy(false);
    } catch (e) {
      setError(e.toString());
      setBusy(false);
    }
  }

  void _resetState() {
    _currentIndex = 0;
    _correctCount = 0;
    _wrongCount = 0;
    _wrongAnswerVocabIds = [];
    _isSubmitted = false;
    _feedbackState = FeedbackState.initial;
    notifyListeners();
  }

  List<Vocabulary> _wrongVocabularies = [];
  List<Vocabulary> get wrongVocabularies => _wrongVocabularies;

  Future<bool> checkAnswer(String input) async {
    if (_isSubmitted || currentVocabulary == null) return false;
    if (input.trim().isEmpty) return false;

    _isSubmitted = true;
    final userAnswer = input.trim().toLowerCase();
    final correctAnswer = currentVocabulary!.word.trim().toLowerCase();
    final isCorrect = userAnswer == correctAnswer;

    if (isCorrect) {
      _correctCount++;
      _feedbackState = FeedbackState.correct;
      _soundService.playCorrect();
    } else {
      _wrongCount++;
      _wrongAnswerVocabIds.add(currentVocabulary!.id);
      _wrongVocabularies.add(currentVocabulary!); // Track for retry
      _feedbackState = FeedbackState.incorrect;
      _soundService.playWrong();
    }

    // Update UI immediately
    notifyListeners();

    return isCorrect;
  }

  void startWrongWordsRetry() {
    if (_wrongVocabularies.isEmpty) return;
    final retryVocabs = List<Vocabulary>.from(_wrongVocabularies);
    _session = GameSession(
      gameResultId: _session!.gameResultId,
      vocabularies: retryVocabs,
    );
    _wrongVocabularies = []; // Reset for the new attempt
    _resetState();
  }

  void nextQuestion() {
    if (_currentIndex < vocabularies.length - 1) {
      _currentIndex++;
      _isSubmitted = false;
      _feedbackState = FeedbackState.initial;
      notifyListeners();
    } else {
      // Finished
      notifyListeners();
    }
  }

  Future<void> submitResult() async {
    if (_session == null) return;
    setBusy(true);
    try {
      await StudyModeService.updateGameResult(
        _session!.gameResultId,
        _correctCount,
        _wrongCount,
        _wrongAnswerVocabIds,
      );
    } catch (e) {
      setError("Failed to submit result: $e");
    } finally {
      setBusy(false);
    }
  }
}
