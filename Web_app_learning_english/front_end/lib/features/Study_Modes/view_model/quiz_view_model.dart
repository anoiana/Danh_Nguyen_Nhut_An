import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/base_view_model.dart';
import '../../Study_Modes/model/quiz_session.dart';
import '../service/study_mode_service.dart';
import '../../../api/sound_service.dart';
import '../../Dictionary/service/dictionary_service.dart';

class QuizViewModel extends BaseViewModel {
  final SoundService _soundService = SoundService();

  QuizSessionV2? _session;
  List<QuizQuestionV2> get questions => _session?.questions ?? [];

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  int _correctCount = 0;
  int _wrongCount = 0;
  List<int> _wrongAnswerVocabIds = [];
  String? _selectedAnswer;
  bool _isAnswered = false;

  int get correctCount => _correctCount;
  int get wrongCount => _wrongCount;
  bool get isAnswered => _isAnswered;
  String? get selectedAnswer => _selectedAnswer;

  QuizQuestionV2? get currentQuestion =>
      questions.isNotEmpty && _currentIndex < questions.length
          ? questions[_currentIndex]
          : null;

  bool get isFinished => _currentIndex >= questions.length;

  Future<void> init(
    int userId,
    int folderId, {
    String subType = 'en_vi',
  }) async {
    setBusy(true);
    try {
      _session = await StudyModeService.startQuizGameV2(
        userId,
        folderId,
        subType: subType,
      );

      if (_session != null) {
        // Fetch missing phonetics in parallel for both question word and options
        final List<Future<QuizQuestionV2>> fetchFutures = [];

        for (int i = 0; i < _session!.questions.length; i++) {
          final question = _session!.questions[i];
          
          fetchFutures.add(() async {
            QuizQuestionV2 updatedQuestion = question;
            
            // 1. Check main phonetic
            if (updatedQuestion.phoneticText == null || updatedQuestion.phoneticText!.isEmpty) {
              final String englishWord = subType == 'en_vi' ? updatedQuestion.word : updatedQuestion.correctAnswer;
              try {
                final results = await DictionaryService.lookupWord(englishWord);
                if (results.isNotEmpty && results.first.phonetic != null) {
                  updatedQuestion = updatedQuestion.copyWith(phoneticText: results.first.phonetic);
                }
              } catch (_) {}
            }

            // 2. Check option phonetics (especially for vi_en mode)
            if (subType == 'vi_en' && updatedQuestion.optionPhonetics != null) {
              List<String> updatedOptionPhonetics = List.from(updatedQuestion.optionPhonetics!);
              bool changed = false;
              
              for (int j = 0; j < updatedQuestion.options.length; j++) {
                if (j < updatedOptionPhonetics.length && (updatedOptionPhonetics[j] == "")) {
                  try {
                    final results = await DictionaryService.lookupWord(updatedQuestion.options[j]);
                    if (results.isNotEmpty && results.first.phonetic != null) {
                      updatedOptionPhonetics[j] = results.first.phonetic!;
                      changed = true;
                    }
                  } catch (_) {}
                }
              }
              if (changed) {
                updatedQuestion = updatedQuestion.copyWith(optionPhonetics: updatedOptionPhonetics);
              }
            }
            
            return updatedQuestion;
          }());
        }

        final updatedQuestions = await Future.wait(fetchFutures);
        _session = QuizSessionV2(
          gameResultId: _session!.gameResultId,
          questions: updatedQuestions,
        );
      }

      _resetState();
      setBusy(false);
    } catch (e) {
      setError(e.toString());
      setBusy(false);
    }
  }

  void _resetState() {
    _currentIndex = 0;
    _correctCount = 0;
    _wrongCount = 0;
    _wrongAnswerVocabIds = [];
    _isAnswered = false;
    _selectedAnswer = null;
    notifyListeners();
  }

  List<QuizQuestionV2> _wrongQuestions = [];
  List<QuizQuestionV2> get wrongQuestions => _wrongQuestions;

  // Handle answer selection
  Future<bool> answerQuestion(String selectedOption) async {
    if (_isAnswered) return false;
    if (currentQuestion == null) return false;

    _isAnswered = true;
    _selectedAnswer = selectedOption;

    // Update UI immediately (Show Green/Red)
    notifyListeners();

    bool isCorrect = selectedOption == currentQuestion!.correctAnswer;

    if (isCorrect) {
      _correctCount++;
      _soundService.playCorrect();
    } else {
      _wrongCount++;
      _wrongAnswerVocabIds.add(currentQuestion!.vocabularyId);
      _wrongQuestions.add(currentQuestion!); // Keep track for retry
      _soundService.playWrong();
    }

    return isCorrect;
  }

  void startWrongQuestionsRetry() {
    if (_wrongQuestions.isEmpty) return;
    final retryQuestions = List<QuizQuestionV2>.from(_wrongQuestions);
    _session = QuizSessionV2(
      gameResultId: _session!.gameResultId,
      questions: retryQuestions,
    );
    _wrongQuestions = []; // Reset for the new attempt
    _resetState();
  }

  void nextQuestion() {
    if (_currentIndex < questions.length - 1) {
      _currentIndex++;
      _isAnswered = false;
      _selectedAnswer = null;
      notifyListeners();
    } else {
      // Game finished logic handled by UI or separate method
      notifyListeners(); // Update UI to show result
    }
  }

  Future<void> submitResult() async {
    if (_session == null) return;
    setBusy(true);
    try {
      await StudyModeService.updateGameResult(
        _session!.gameResultId,
        _correctCount,
        _wrongCount,
        _wrongAnswerVocabIds,
      );
    } catch (e) {
      setError("Failed to submit result: $e");
    } finally {
      setBusy(false);
    }
  }
}
