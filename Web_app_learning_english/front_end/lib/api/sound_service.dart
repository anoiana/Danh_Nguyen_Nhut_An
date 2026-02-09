import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Service for managing sound effects in the game
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();

  // Free sound URLs
  static const String _correctSoundUrl =
      'https://assets.mixkit.co/active_storage/sfx/2000/2000-preview.mp3'; // Correct ding
  static const String _wrongSoundUrl =
      'https://assets.mixkit.co/active_storage/sfx/2003/2003-preview.mp3';

  bool _isMuted = false;

  /// Getter to check mute status
  bool get isMuted => _isMuted;

  /// Toggle mute status
  void toggleMute() {
    _isMuted = !_isMuted;
  }

  /// Play correct answer sound (fire and forget)
  Future<void> playCorrect() async {
    if (_isMuted) return;
    try {
      await _correctPlayer.stop();
      await _correctPlayer.play(UrlSource(_correctSoundUrl));
    } catch (e) {
      print('Error playing correct sound: $e');
    }
  }

  /// Play wrong answer sound (fire and forget)
  Future<void> playWrong() async {
    if (_isMuted) return;
    try {
      await _wrongPlayer.stop();
      await _wrongPlayer.play(UrlSource(_wrongSoundUrl));
    } catch (e) {
      print('Error playing wrong sound: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _correctPlayer.dispose();
    _wrongPlayer.dispose();
  }
}
