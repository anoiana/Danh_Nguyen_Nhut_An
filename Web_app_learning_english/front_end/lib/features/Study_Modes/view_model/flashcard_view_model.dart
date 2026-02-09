import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/base_view_model.dart';
import '../../Vocabulary/model/vocabulary.dart';
import '../model/game_session.dart';
import '../service/study_mode_service.dart';

class FlashcardSettings {
  bool loopMode;
  int displayDuration;
  bool startWithMeaningSide;
  bool autoSpeak;

  FlashcardSettings({
    this.loopMode = false,
    this.displayDuration = 3,
    this.startWithMeaningSide = false,
    this.autoSpeak = true,
  });
}

class FlashcardViewModel extends BaseViewModel {
  final StudyModeService _service = StudyModeService();

  GameSession? _session;
  List<Vocabulary> _vocabularies = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isPlaying = false;
  Timer? _timer;

  // Settings
  FlashcardSettings _settings = FlashcardSettings();

  // Getters
  List<Vocabulary> get vocabularies => _vocabularies;
  int get currentIndex => _currentIndex;
  bool get isFlipped => _isFlipped;
  bool get isPlaying => _isPlaying;
  FlashcardSettings get settings => _settings;
  Vocabulary? get currentVocabulary =>
      _vocabularies.isNotEmpty ? _vocabularies[_currentIndex] : null;

  // Direction for animation
  bool _isGoingForward = true;
  bool get isGoingForward => _isGoingForward;

  Future<void> init(int userId, int folderId) async {
    setBusy(true);
    try {
      _session = await _service.startGenericGame(userId, folderId, 'flashcard');
      _vocabularies = _session?.vocabularies ?? [];
      _currentIndex = 0;
      _isFlipped = _settings.startWithMeaningSide;
      setBusy(false);
    } catch (e) {
      setError(e.toString());
      setBusy(false);
    }
  }

  // --- Actions ---

  void flipCard() {
    _isFlipped = !_isFlipped;
    notifyListeners();
  }

  void nextCard({bool fromAutoPlay = false}) {
    // If user manually clicks next, stop auto play unless we want to keep it?
    // Usually manual interaction stops auto play to avoid confusion.
    if (!fromAutoPlay) stopAutoPlay();

    if (_vocabularies.isEmpty) return;

    if (_currentIndex >= _vocabularies.length - 1 && !_settings.loopMode) {
      if (fromAutoPlay) stopAutoPlay();
      return;
    }

    _isGoingForward = true;
    _currentIndex = (_currentIndex + 1) % _vocabularies.length;
    _isFlipped = _settings.startWithMeaningSide;
    notifyListeners();
  }

  void previousCard() {
    stopAutoPlay();
    if (_currentIndex > 0) {
      _isGoingForward = false;
      _currentIndex--;
      _isFlipped = _settings.startWithMeaningSide;
      notifyListeners();
    }
  }

  // --- Auto Play ---

  void toggleAutoPlay() {
    if (_isPlaying) {
      stopAutoPlay();
    } else {
      startAutoPlay();
    }
  }

  void startAutoPlay() {
    _isPlaying = true;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: _settings.displayDuration), (
      timer,
    ) {
      nextCard(fromAutoPlay: true);
    });
  }

  void stopAutoPlay() {
    _timer?.cancel();
    _isPlaying = false;
    notifyListeners();
  }

  // --- Settings ---
  void updateSettings({
    bool? loopMode,
    int? displayDuration,
    bool? startWithMeaningSide,
    bool? autoSpeak,
  }) {
    if (loopMode != null) _settings.loopMode = loopMode;
    if (displayDuration != null) {
      _settings.displayDuration = displayDuration;
      // Restart timer if running to apply new duration immediately
      if (_isPlaying) startAutoPlay();
    }
    if (startWithMeaningSide != null)
      _settings.startWithMeaningSide = startWithMeaningSide;
    if (autoSpeak != null) _settings.autoSpeak = autoSpeak;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
