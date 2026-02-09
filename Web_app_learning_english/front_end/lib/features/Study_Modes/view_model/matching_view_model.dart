import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/base_view_model.dart';
import '../../Vocabulary/model/vocabulary.dart';
import '../model/game_session.dart';
import '../model/matching_tile.dart';
import '../service/study_mode_service.dart';
import '../../../api/auth_service.dart';
import '../../../api/sound_service.dart';

class MatchingViewModel extends BaseViewModel {
  final StudyModeService _service = StudyModeService();
  final SoundService _soundService = SoundService();

  GameSession? _session;
  List<MatchingTile> _tiles = [];
  List<MatchingTile> get tiles => _tiles;

  MatchingTile? _firstSelected;
  MatchingTile? _secondSelected;
  bool _isProcessingMismatch = false;

  int _moves = 0;
  int get moves => _moves;

  int _matchedPairs = 0;
  int get matchedPairs => _matchedPairs;

  int get totalPairs => _session?.vocabularies.length ?? 0;

  bool get isFinished => totalPairs > 0 && _matchedPairs == totalPairs;

  // Timer
  Timer? _timer;
  int _secondsElapsed = 0;
  int get secondsElapsed => _secondsElapsed;
  String get timeString {
    final m = (_secondsElapsed / 60).floor().toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> init(int userId, int folderId) async {
    setBusy(true);
    try {
      // Use 'flashcard' to just get the list of words for now as matching logic is frontend side
      // Or 'matching' if backend supports. Let's use 'flashcard' to be safe since we just need vocab list.
      // Actually let's use 'matching' to be semantically correct, if it fails I'll swap.
      // But wait, the user showed me 'GameSelectionScreen' which implies 'writing', 'flashcard' exist.
      // I'll stick to 'flashcard' gameType to ensure providing data, as matching game is just a UI layer over vocabs.
      // Correction: Use 'matching' if you want backend to track it as matching game stats.
      // I will assume 'matching' is valid or will default to flashcard data structure.
      // Let's rely on standard GameSession return.
      _session = await _service.startGenericGame(userId, folderId, 'matching');
      _setupGame();
      setBusy(false);
    } catch (e) {
      // Fallback to flashcard if matching not found? No, better show error.
      // Actually, for safety let's just try 'matching'.
      try {
        if (e.toString().contains("Invalid game type")) {
          _session = await _service.startGenericGame(
            userId,
            folderId,
            'flashcard',
          );
          _setupGame();
          setBusy(false);
        } else {
          setError(e.toString());
          setBusy(false);
        }
      } catch (e2) {
        setError(e.toString());
        setBusy(false);
      }
    }
  }

  void _setupGame() {
    if (_session == null) return;
    _tiles = [];
    _matchedPairs = 0;
    _moves = 0;
    _secondsElapsed = 0;
    _firstSelected = null;
    _secondSelected = null;
    _isProcessingMismatch = false;

    for (var vocab in _session!.vocabularies) {
      // Add word tile
      _tiles.add(
        MatchingTile(
          id: "${vocab.id}_word",
          vocabId: vocab.id,
          content: vocab.word,
          isWord: true,
        ),
      );
      // Add meaning tile
      String meaning = vocab.userDefinedMeaning ?? "No meaning";
      _tiles.add(
        MatchingTile(
          id: "${vocab.id}_meaning",
          vocabId: vocab.id,
          content: meaning,
          isWord: false,
        ),
      );
    }
    _tiles.shuffle();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      notifyListeners();
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  Future<void> selectTile(MatchingTile tile) async {
    if (_isProcessingMismatch || tile.isMatched || tile.isSelected) return;

    tile.isSelected = true;
    notifyListeners();

    if (_firstSelected == null) {
      _firstSelected = tile;
    } else {
      _secondSelected = tile;
      _moves++;
      _isProcessingMismatch = true;

      await _checkMatch();
    }
  }

  final Set<int> _failedVocabIds = {};
  List<Vocabulary> get wrongVocabularies {
    if (_session == null) return [];
    return _session!.vocabularies
        .where((v) => _failedVocabIds.contains(v.id))
        .toList();
  }

  Future<void> _checkMatch() async {
    if (_firstSelected!.vocabId == _secondSelected!.vocabId) {
      // MATCH
      _firstSelected!.isMatched = true;
      _secondSelected!.isMatched = true;
      _firstSelected!.isSelected = false;
      _secondSelected!.isSelected = false; // Keep them visible as matched

      _matchedPairs++;
      await _soundService.playCorrectAndWait();

      _firstSelected = null;
      _secondSelected = null;
      _isProcessingMismatch = false;

      if (isFinished) {
        stopTimer();
        submitResult();
      }
      notifyListeners();
    } else {
      // MISMATCH
      _failedVocabIds.add(_firstSelected!.vocabId);
      _failedVocabIds.add(_secondSelected!.vocabId);

      _firstSelected!.isError = true;
      _secondSelected!.isError = true;
      await _soundService.playWrongAndWait();
      notifyListeners();

      // Wait and reset
      await Future.delayed(const Duration(milliseconds: 1000));
      if (_firstSelected != null) {
        _firstSelected!.isSelected = false;
        _firstSelected!.isError = false;
      }
      if (_secondSelected != null) {
        _secondSelected!.isSelected = false;
        _secondSelected!.isError = false;
      }

      _firstSelected = null;
      _secondSelected = null;
      _isProcessingMismatch = false;
      notifyListeners();
    }
  }

  void startWrongWordsRetry() {
    final retryVocabs = wrongVocabularies;
    if (retryVocabs.isEmpty || _session == null) return;

    _session = GameSession(
      gameResultId: _session!.gameResultId,
      vocabularies: retryVocabs,
    );
    _failedVocabIds.clear();
    _setupGame();
  }

  Future<void> submitResult() async {
    if (_session == null) return;
    try {
      await AuthService.updateGameResult(
        _session!.gameResultId,
        _matchedPairs,
        _failedVocabIds.length,
        _failedVocabIds.toList(),
      );
    } catch (e) {
      setError("Result submission notice: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
