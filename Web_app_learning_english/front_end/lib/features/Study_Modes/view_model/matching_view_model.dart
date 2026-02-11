import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/base_view_model.dart';
import '../../Vocabulary/model/vocabulary.dart';
import '../model/game_session.dart';
import '../model/matching_tile.dart';
import '../service/study_mode_service.dart';
import '../../../api/sound_service.dart';
import '../../../api/tts_service.dart';

class MatchingViewModel extends BaseViewModel {
  final SoundService _soundService = SoundService();
  final TextToSpeechService _ttsService = TextToSpeechService();

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
      _session = await StudyModeService.startGenericGame(
        userId,
        folderId,
        'matching',
      );
      _setupGame();
      setBusy(false);
    } catch (e) {
      // Fallback to flashcard if matching not found
      try {
        if (e.toString().contains("Invalid game type")) {
          _session = await StudyModeService.startGenericGame(
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
      if (_firstSelected == tile) {
        // Prevent selecting the same tile again as second selection
        return;
      }
      _secondSelected = tile;
      _moves++;
      _isProcessingMismatch = true;

      await _checkMatch();
    }
  }

  void deselectTile(MatchingTile tile) {
    if (tile.isMatched || _isProcessingMismatch) return;

    if (_firstSelected == tile) {
      tile.isSelected = false;
      _firstSelected = null;
      notifyListeners();
    }
    // We generally don't need to handle _secondSelected because it triggers match check immediately
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
      _soundService.playCorrect();

      // Speak text
      String textToSpeak = "";
      if (_firstSelected!.isWord) {
        textToSpeak = _firstSelected!.content;
      } else {
        // Find the word from the session vocabularies using ID, or if the second one is word (which it should be if first is not)
        // Actually since it's a pair one MUST be word and one MUST be meaning
        textToSpeak = _secondSelected!.content;
      }
      _ttsService.speak(textToSpeak);

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
      _soundService.playWrong();
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
    setBusy(true);
    try {
      await StudyModeService.updateGameResult(
        _session!.gameResultId,
        _matchedPairs,
        _failedVocabIds.length,
        _failedVocabIds.toList(),
      );
    } catch (e) {
      setError("Result submission notice: $e");
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
