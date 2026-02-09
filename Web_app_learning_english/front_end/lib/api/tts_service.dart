// lib/services/tts_service.dart

import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Cần cho StreamController và Stream
import 'package:flutter/foundation.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // Constants
  static const String _speechRateKey = 'tts_speech_rate';
  static const double _defaultSpeechRate = 0.5;
  static const double _defaultPitch = 1.0;
  static const String _defaultLanguage = "en-US";

  // Singleton
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() {
    return _instance;
  }
  TextToSpeechService._internal();

  // --- START: CÁC BIẾN STATE VÀ STREAM CONTROLLER MỚI ---
  // Lưu trữ các giá trị hiện tại
  double _speechRate = _defaultSpeechRate;
  double _pitch = _defaultPitch;

  // Stream để thông báo trạng thái phát cho UI
  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  final StreamController<double> _speechRateController =
      StreamController<double>.broadcast();

  // Public getters để UI có thể truy cập
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<double> get speechRateStream => _speechRateController.stream;
  double get speechRate => _speechRate;
  // --- END: CÁC BIẾN STATE VÀ STREAM CONTROLLER MỚI ---

  Future<void> init() async {
    if (_isInitialized) return;

    // Tải tốc độ đã lưu từ SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _speechRate = prefs.getDouble(_speechRateKey) ?? _defaultSpeechRate;
    _speechRateController.add(_speechRate); // Thông báo giá trị ban đầu

    await _flutterTts.setLanguage(_defaultLanguage);

    // Attempt to set Google TTS engine if available (Android)
    try {
      final engines = await _flutterTts.getEngines;
      if (engines != null) {
        for (var engine in engines) {
          if (engine.toString().toLowerCase().contains('google')) {
            await _flutterTts.setEngine(engine);
            break;
          }
        }
      }
    } catch (e) {
      debugPrint("Error setting TTS engine: $e");
    }

    // Reset language to ensure it uses the engine's voice for this language
    await _flutterTts.setLanguage(_defaultLanguage);

    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);

    // --- START: CÀI ĐẶT CÁC HANDLER ĐỂ GIAO TIẾP VỚI UI ---

    // Khi TTS bắt đầu phát
    _flutterTts.setStartHandler(() {
      _isPlayingController.add(true);
    });

    // Khi TTS phát xong
    _flutterTts.setCompletionHandler(() {
      _isPlayingController.add(false);
      _progressController.add(1.0); // Hoàn thành 100%
    });

    // Theo dõi tiến trình phát âm
    _flutterTts.setProgressHandler((
      String text,
      int start,
      int end,
      String word,
    ) {
      if (text.isNotEmpty) {
        // Tính toán phần trăm tiến trình và gửi cho UI
        final progress = (start / text.length).clamp(0.0, 1.0);
        _progressController.add(progress);
      }
    });

    // Khi có lỗi xảy ra
    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      _isPlayingController.add(false); // Dừng trạng thái đang phát
      _progressController.add(0.0); // Reset tiến trình
    });
    // --- END: CÀI ĐẶT CÁC HANDLER ---

    _isInitialized = true;
  }

  // --- START: CÁC HÀM CÔNG KHAI MỚI ĐỂ ĐIỀU KHIỂN LINH HOẠT ---

  /// Đặt tốc độ nói mới và lưu vào SharedPreferences.
  /// rate: 0.0 (chậm nhất) -> 1.0 (nhanh nhất)
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await init();
    _speechRate = rate;
    await _flutterTts.setSpeechRate(_speechRate);

    // Lưu tốc độ vào SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, rate);

    // Thông báo cho UI
    _speechRateController.add(rate);
  }

  /// Đặt cao độ giọng nói mới.
  /// pitch: 0.5 (trầm) -> 1.5 (cao)
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) await init();
    _pitch = pitch;
    await _flutterTts.setPitch(_pitch);
  }
  // --- END: CÁC HÀM CÔNG KHAI MỚI ---

  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (text.isNotEmpty) {
      // Trước khi nói, reset tiến trình về 0
      _progressController.add(0.0);
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    var result = await _flutterTts.stop();
    // Nếu dừng thành công, cập nhật trạng thái
    if (result == 1) {
      _isPlayingController.add(false);
    }
  }

  // Giải phóng tài nguyên khi không cần thiết (quan trọng!)
  void dispose() {
    _isPlayingController.close();
    _progressController.close();
    _speechRateController.close();
  }
}
