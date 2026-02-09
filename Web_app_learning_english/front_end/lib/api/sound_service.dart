import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Service quản lý âm thanh hiệu ứng trong game
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();

  // URLs âm thanh miễn phí
  static const String _correctSoundUrl =
      'https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'; // Correct ding

  // Các lựa chọn âm thanh sai (Wrong sound options):
  // Option 1 (Buzz): 'https://assets.mixkit.co/active_storage/sfx/2955/2955-preview.mp3'
  // Option 2 (Pop): 'https://assets.mixkit.co/active_storage/sfx/2656/2656-preview.mp3'
  // Option 3 (Retro Error - CURRENT): 'https://assets.mixkit.co/active_storage/sfx/893/893-preview.mp3'
  // Option 4 (Click Error): 'https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3'

  static const String _wrongSoundUrl =
      'https://assets.mixkit.co/active_storage/sfx/2955/2955-preview.mp3';

  bool _isMuted = false;

  /// Getter để kiểm tra trạng thái tắt tiếng
  bool get isMuted => _isMuted;

  /// Bật/tắt âm thanh
  void toggleMute() {
    _isMuted = !_isMuted;
  }

  /// Phát âm thanh trả lời đúng (không chờ)
  Future<void> playCorrect() async {
    if (_isMuted) return;
    try {
      await _correctPlayer.stop();
      await _correctPlayer.play(UrlSource(_correctSoundUrl));
    } catch (e) {
      print('Error playing correct sound: $e');
    }
  }

  /// Phát âm thanh trả lời đúng và CHỜ cho đến khi phát xong
  Future<void> playCorrectAndWait() async {
    if (_isMuted) return;
    try {
      final completer = Completer<void>();

      // Lắng nghe sự kiện khi âm thanh phát xong
      StreamSubscription? subscription;
      subscription = _correctPlayer.onPlayerComplete.listen((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        subscription?.cancel();
      });

      await _correctPlayer.stop();
      await _correctPlayer.play(UrlSource(_correctSoundUrl));

      // Chờ âm thanh phát xong (timeout sau 2 giây để tránh treo)
      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          subscription?.cancel();
        },
      );
    } catch (e) {
      print('Error playing correct sound: $e');
    }
  }

  /// Phát âm thanh trả lời sai (không chờ)
  Future<void> playWrong() async {
    if (_isMuted) return;
    try {
      await _wrongPlayer.stop();
      await _wrongPlayer.play(UrlSource(_wrongSoundUrl));
    } catch (e) {
      print('Error playing wrong sound: $e');
    }
  }

  /// Phát âm thanh trả lời sai và CHỜ cho đến khi phát xong
  Future<void> playWrongAndWait() async {
    if (_isMuted) return;
    try {
      final completer = Completer<void>();

      // Lắng nghe sự kiện khi âm thanh phát xong
      StreamSubscription? subscription;
      subscription = _wrongPlayer.onPlayerComplete.listen((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
        subscription?.cancel();
      });

      await _wrongPlayer.stop();
      await _wrongPlayer.play(UrlSource(_wrongSoundUrl));

      // Chờ âm thanh phát xong (timeout sau 2 giây để tránh treo)
      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          subscription?.cancel();
        },
      );
    } catch (e) {
      print('Error playing wrong sound: $e');
    }
  }

  /// Giải phóng tài nguyên
  void dispose() {
    _correctPlayer.dispose();
    _wrongPlayer.dispose();
  }
}
