import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/base_view_model.dart';
import '../../Vocabulary/service/vocabulary_service.dart';
import '../model/dictionary_entry.dart';
import '../../Folders/model/folder.dart';

class DictionaryViewModel extends BaseViewModel {
  final VocabularyService _vocabularyService = VocabularyService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<DictionaryEntry> _entries = [];
  List<DictionaryEntry> get entries => _entries;

  String _currentWord = '';
  String get currentWord => _currentWord;

  Future<void> lookupWord(String word) async {
    _currentWord = word;
    setBusy(true);
    try {
      _entries = await _vocabularyService.lookupWord(word);
      setBusy(false);
    } catch (e) {
      setError(e.toString());
      setBusy(false);
    }
  }

  Future<void> playAudio(String? url) async {
    if (url != null && url.isNotEmpty) {
      try {
        await _audioPlayer.play(UrlSource(url));
      } catch (e) {
        debugPrint('Audio playback error: $e');
      }
    }
  }

  Future<bool> createVocabulary({
    required DictionaryEntry entry,
    required int folderId,
    required String userDefinedMeaning,
    String? userDefinedPartOfSpeech,
    String? userImageBase64,
    double? imageAlignmentX,
    double? imageAlignmentY,
  }) async {
    try {
      await _vocabularyService.createVocabulary(
        entry: entry,
        folderId: folderId,
        userDefinedMeaning: userDefinedMeaning,
        userDefinedPartOfSpeech: userDefinedPartOfSpeech,
        userImageBase64: userImageBase64,
        imageAlignmentX: imageAlignmentX,
        imageAlignmentY: imageAlignmentY,
      );
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
