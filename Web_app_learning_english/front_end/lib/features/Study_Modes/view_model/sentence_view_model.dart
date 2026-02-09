import 'package:flutter/material.dart';
import '../../../core/base_view_model.dart';
import '../model/game_session.dart';
import '../../Vocabulary/model/vocabulary.dart';
import '../service/study_mode_service.dart';
import '../../../api/sound_service.dart';
import '../../../api/tts_service.dart';

enum FeedbackState { initial, loading, correct, incorrect }

class SentenceViewModel extends BaseViewModel {
  final TextToSpeechService _ttsService = TextToSpeechService();
  final SoundService _soundService = SoundService();

  GameSession? _session;
  GameSession? get session => _session;

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

  String _feedbackMessage = '';
  String get feedbackMessage => _feedbackMessage;

  Vocabulary? get currentVocab =>
      _session != null && _currentIndex < _session!.vocabularies.length
          ? _session!.vocabularies[_currentIndex]
          : null;

  String get partOfSpeech =>
      (currentVocab?.meanings?.isNotEmpty ?? false)
          ? currentVocab!.meanings!.first.partOfSpeech
          : '';

  Future<void> init(int userId, int folderId) async {
    setBusy(true);
    clearError();
    _resetState();

    try {
      // Try 'writing' mode first (generic fallback handling)
      try {
        _session = await StudyModeService.startGenericGame(
          userId,
          folderId,
          'writing',
        );
      } catch (e) {
        debugPrint('Writing mode failed ($e), falling back to flashcard...');
        // Fallback to 'flashcard'
        _session = await StudyModeService.startGenericGame(
          userId,
          folderId,
          'flashcard',
        );
      }

      if (_session == null) {
        throw Exception("Không thể tải dữ liệu bài học.");
      }

      // Safe TTS init
      try {
        await _ttsService.init();
      } catch (e) {
        debugPrint('TTS Init Warning: $e');
      }
    } catch (e) {
      debugPrint('Error initializing Sentence Game: $e');
      setError(e.toString().replaceAll('Exception: ', ''));
    } finally {
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
    _feedbackMessage = '';
  }

  Future<void> checkAnswer(String answer) async {
    if (_isSubmitted || answer.trim().isEmpty || currentVocab == null) return;

    _isSubmitted = true;
    _feedbackState = FeedbackState.loading;
    notifyListeners();

    try {
      final response = await StudyModeService.checkWritingSentence(
        currentVocab!.id,
        answer.trim(),
      );

      _feedbackMessage = response.feedback;
      _feedbackState =
          response.isCorrect ? FeedbackState.correct : FeedbackState.incorrect;

      if (response.isCorrect) {
        _correctCount++;
        _soundService.playCorrect();
      } else {
        _wrongCount++;
        _wrongAnswerVocabIds.add(currentVocab!.id);
        _soundService.playWrong();
      }

      _ttsService.speak(currentVocab!.word);
    } catch (e) {
      _feedbackState = FeedbackState.incorrect;
      _feedbackMessage = 'Lỗi kết nối. Vui lòng thử lại.';
      _wrongCount++;
      if (!_wrongAnswerVocabIds.contains(currentVocab!.id)) {
        _wrongAnswerVocabIds.add(currentVocab!.id);
      }
      _soundService.playWrong();
    }
    notifyListeners();
  }

  void nextSentence() {
    if (_session != null && _currentIndex < _session!.vocabularies.length) {
      _currentIndex++;
      _isSubmitted = false;
      _feedbackState = FeedbackState.initial;
      _feedbackMessage = '';
      notifyListeners();
    } else {
      // Game finished, handle result submitting if needed here or in UI
    }
  }

  Future<void> retryGame() async {
    // Logic to retry logic if API supported retrying sentence game specifically
    // For now, we might just restart the current session or fetch new one.
    // Assuming simplistic retry for now similar to other modes
    setBusy(true);
    try {
      if (_session != null) {
        final newSession = await StudyModeService.startRetryGame(
          _session!.gameResultId,
        );
        if (newSession is GameSession) {
          // Ensure type match
          _session = newSession;
          _resetState();
        }
      }
    } catch (e) {
      debugPrint("Error retrying: $e");
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }

  Future<void> submitGameResult() async {
    if (_session == null) return;
    try {
      await StudyModeService.updateGameResult(
        _session!.gameResultId,
        _correctCount,
        _wrongCount,
        _wrongAnswerVocabIds,
      );
    } catch (e) {
      debugPrint("Error updating game result: $e");
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }
}
