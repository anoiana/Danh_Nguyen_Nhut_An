import 'package:flutter/material.dart';
import '../../../core/base_view_model.dart';

class StudyModesViewModel extends BaseViewModel {
  // Navigation logics for different game modes will be here
  // For now, it mainly holds checking conditions logic

  bool canPlayFlashcard(int vocabularyCount) => vocabularyCount >= 1;
  bool canPlayQuiz(int vocabularyCount) => vocabularyCount >= 4;
  bool canPlayWriting(int vocabularyCount) => vocabularyCount >= 1;
  bool canPlayMatching(int vocabularyCount) => vocabularyCount >= 4;
  // Add other checks...

  String get disabledMessageQuiz => 'Cần ít nhất 4 từ vựng.';
  String get disabledMessageDefault => 'Cần ít nhất 1 từ vựng.';

  // Future logic to fetch study sessions...
}
