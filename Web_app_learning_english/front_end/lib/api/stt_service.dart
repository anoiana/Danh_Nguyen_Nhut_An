// lib/api/stt_service.dart
// Speech-to-Text Service for voice recognition

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

enum SttStatus { idle, listening, processing, error }

class SpeechToTextService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;

  // Stream controllers for state management
  final StreamController<SttStatus> _statusController =
      StreamController<SttStatus>.broadcast();
  final StreamController<String> _recognizedTextController =
      StreamController<String>.broadcast();
  final StreamController<double> _soundLevelController =
      StreamController<double>.broadcast();

  // Public streams
  Stream<SttStatus> get statusStream => _statusController.stream;
  Stream<String> get recognizedTextStream => _recognizedTextController.stream;
  Stream<double> get soundLevelStream => _soundLevelController.stream;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;

  // Singleton pattern
  static final SpeechToTextService _instance = SpeechToTextService._internal();
  factory SpeechToTextService() => _instance;
  SpeechToTextService._internal();

  /// Initialize the speech recognition service. Returns true if successful.
  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: kDebugMode,
      );

      if (_isInitialized) {
        debugPrint('STT Service initialized successfully');
      } else {
        debugPrint('STT Service initialization failed');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing STT: $e');
      return false;
    }
  }

  /// Check if speech recognition is available on the device
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await init();
    }
    return _isInitialized;
  }

  /// Start listening for speech input from the microphone
  /// [localeId] Language code (default: en-US)
  /// [listenFor] Duration to listen before automatically stopping
  /// [pauseFor] Duration of silence before automatically stopping
  Future<void> startListening({
    String localeId = 'en-US',
    Duration listenFor = const Duration(seconds: 10),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      final success = await init();
      if (!success) {
        _statusController.add(SttStatus.error);
        return;
      }
    }

    if (_isListening) {
      await stopListening();
    }

    _isListening = true;
    _statusController.add(SttStatus.listening);

    await _speechToText.listen(
      onResult: _onResult,
      listenFor: listenFor,
      pauseFor: pauseFor,
      localeId: localeId,
      onSoundLevelChange: (level) {
        _soundLevelController.add(level);
      },
      cancelOnError: true,
      partialResults: true,
      // listenMode: ListenMode.confirmation,
    );
  }

  /// Stop listening (stops recording but processes current result)
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _speechToText.stop();
    _isListening = false;
    _statusController.add(SttStatus.idle);
  }

  /// Cancel listening immediately (stops recording and discards result)
  Future<void> cancel() async {
    await _speechToText.cancel();
    _isListening = false;
    _statusController.add(SttStatus.idle);
  }

  // Private handlers
  void _onResult(SpeechRecognitionResult result) {
    _recognizedTextController.add(result.recognizedWords);

    if (result.finalResult) {
      _isListening = false;
      _statusController.add(SttStatus.processing);
    }
  }

  void _onStatus(String status) {
    debugPrint('STT Status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _statusController.add(SttStatus.idle);
    }
  }

  void _onError(SpeechRecognitionError error) {
    debugPrint('STT Error: ${error.errorMsg}');
    _isListening = false;
    _statusController.add(SttStatus.error);
  }

  /// Compare spoken text with expected text using fuzzy matching and Levenshtein distance
  /// Returns true if they are considered a match
  static bool compareWords(String spoken, String expected) {
    // Remove punctuation and extra spaces
    // Match anything that is NOT a letter, number, or whitespace using unicode properties
    final cleanSpoken =
        spoken
            .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
            .trim()
            .toLowerCase();

    final cleanExpected =
        expected
            .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
            .trim()
            .toLowerCase();

    debugPrint('STT Compare: "$cleanSpoken" vs "$cleanExpected"');

    // Exact match
    if (cleanSpoken == cleanExpected) return true;

    // Check if the expected word appears as a WHOLE WORD in the sentence
    // This allows "apple" in "I eat an apple", but REJECTS "apple" in "pineapple"
    final escapedExpected = RegExp.escape(cleanExpected);
    final wordBoundaryRegExp = RegExp(r'\b' + escapedExpected + r'\b');
    if (wordBoundaryRegExp.hasMatch(cleanSpoken)) return true;

    // Strict Levenshtein Check (Hard Mode)
    final distance = _levenshteinDistance(cleanSpoken, cleanExpected);
    final maxLength = cleanExpected.length;

    // For words 5 characters or less: MUST BE EXACT MATCH (0 errors)
    if (maxLength <= 5) {
      debugPrint(
        'STT Strict Check (<=5 chars): Distance $distance (Must be 0)',
      );
      return distance == 0;
    }

    // For words longer than 5 characters: Allow max 20% error
    // e.g. 6-9 chars -> 1 error allowed
    //     10+ chars -> 2 errors allowed
    final maxAllowed = (maxLength * 0.2).ceil();
    debugPrint(
      'STT Strict Check (>5 chars): Distance $distance (Max Allowed: $maxAllowed)',
    );

    return distance <= maxAllowed;
  }

  /// Calculate the Levenshtein edit distance between two strings
  /// Used to measure difference between spoken and expected words
  static int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> dp = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[s1.length][s2.length];
  }

  /// Dispose and close all streams to free resources
  void dispose() {
    _speechToText.stop();
    _statusController.close();
    _recognizedTextController.close();
    _soundLevelController.close();
  }
}
