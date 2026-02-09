import 'package:audioplayers/audioplayers.dart';
import '../../../core/base_view_model.dart';
import '../../../api/tts_service.dart';
import '../../Dictionary/service/dictionary_service.dart';
import '../model/vocabulary.dart';

class VocabularyDetailViewModel extends BaseViewModel {
  final TextToSpeechService _ttsService = TextToSpeechService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Vocabulary? _vocabulary;
  Vocabulary? get vocabulary => _vocabulary;

  void init(Vocabulary vocab) {
    _vocabulary = vocab;
    _ttsService.init();
  }

  Future<void> playAudio(String? url) async {
    if (url != null && url.isNotEmpty) {
      try {
        await _audioPlayer.play(UrlSource(url));
      } catch (e) {
        // Handle error
      }
    }
  }

  Future<void> speak(String text, {double rate = 0.5}) async {
    await _ttsService.stop();
    await _ttsService.setSpeechRate(rate);
    await _ttsService.speak(text);
  }

  Future<String> translate(String text) async {
    return await DictionaryService.translateWord(text);
  }

  @override
  void dispose() {
    _ttsService.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}
