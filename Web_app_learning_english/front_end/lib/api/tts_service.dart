// lib/services/tts_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();

  factory TextToSpeechService() {
    return _instance;
  }

  TextToSpeechService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // Constants
  static const String _speechRateKey = 'tts_speech_rate';
  static const double _defaultSpeechRate = 0.5;
  static const double _defaultPitch = 1.0;
  static const String _defaultLanguage = "en-US";

  // State variables
  double _speechRate = _defaultSpeechRate;
  double _pitch = _defaultPitch;

  // Stream Controllers
  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();
  final StreamController<double> _progressController =
      StreamController<double>.broadcast();
  final StreamController<double> _speechRateController =
      StreamController<double>.broadcast();

  // Public Getters
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<double> get progressStream => _progressController.stream;
  Stream<double> get speechRateStream => _speechRateController.stream;
  double get speechRate => _speechRate;

  /// Initialize the TTS service and setup handlers
  Future<void> init() async {
    if (_isInitialized) return;

    // Load saved settings
    final prefs = await SharedPreferences.getInstance();
    _speechRate = prefs.getDouble(_speechRateKey) ?? _defaultSpeechRate;
    _speechRateController.add(_speechRate);

    // Setup TTS Engine and Language
    await _flutterTts.setLanguage(_defaultLanguage);
    await _trySetGoogleEngine();

    // Apply settings
    await _flutterTts.setLanguage(_defaultLanguage);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setPitch(_pitch);

    // Setup Events
    _setupHandlers();

    _isInitialized = true;
  }

  /// Attempt to set Google TTS engine if available (Android)
  Future<void> _trySetGoogleEngine() async {
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
  }

  void _setupHandlers() {
    _flutterTts.setStartHandler(() {
      _isPlayingController.add(true);
    });

    _flutterTts.setCompletionHandler(() {
      _isPlayingController.add(false);
      _progressController.add(1.0);
    });

    _flutterTts.setProgressHandler((
      String text,
      int start,
      int end,
      String word,
    ) {
      if (text.isNotEmpty) {
        final progress = (start / text.length).clamp(0.0, 1.0);
        _progressController.add(progress);
      }
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint("TTS Error: $msg");
      _isPlayingController.add(false);
      _progressController.add(0.0);
    });
  }

  /// Speak the provided text
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (text.isNotEmpty) {
      _progressController.add(0.0);
      await _flutterTts.speak(text);
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    if (!_isInitialized) return;
    var result = await _flutterTts.stop();
    if (result == 1) {
      _isPlayingController.add(false);
    }
  }

  /// Set new speech rate and save to SharedPreferences
  /// rate: 0.0 (slowest) -> 1.0 (fastest)
  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await init();
    _speechRate = rate;
    await _flutterTts.setSpeechRate(_speechRate);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, rate);

    _speechRateController.add(rate);
  }

  /// Set new voice pitch
  /// pitch: 0.5 (low) -> 1.5 (high)
  Future<void> setPitch(double pitch) async {
    if (!_isInitialized) await init();
    _pitch = pitch;
    await _flutterTts.setPitch(_pitch);
  }

  /// Dispose resources
  void dispose() {
    _isPlayingController.close();
    _progressController.close();
    _speechRateController.close();
    _flutterTts.stop();
  }
}
