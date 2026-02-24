import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/tts_service.dart';
import '../view_model/quiz_view_model.dart';
import '../model/quiz_session.dart';
import '../../../../core/widgets/custom_loading_widget.dart';
import '../../../../core/widgets/custom_error_widget.dart';
import '../../../core/widgets/game_finish_dialog.dart';

class QuizView extends StatefulWidget {
  final int folderId;
  final String folderName;
  final String subType;

  const QuizView({
    super.key,
    required this.folderId,
    required this.folderName,
    this.subType = 'en_vi',
  });

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView>
    with SingleTickerProviderStateMixin {
  final QuizViewModel _viewModel = QuizViewModel();
  final TextToSpeechService _ttsService = TextToSpeechService();

  // Colors

  static const Color correctColor = Colors.green;
  static const Color wrongColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _loadData();
    _ttsService.init();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      await _viewModel.init(userId, widget.folderId, subType: widget.subType);
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _speakQuestion(QuizQuestionV2 question) async {
    await _ttsService.setSpeechRate(0.5);
    String textToSpeak;
    // Determine which text is English based on quiz type
    if (widget.subType == 'en_vi') {
      // English -> Vietnamese: Question (word) is English
      textToSpeak = question.word;
    } else {
      // Vietnamese -> English: Answer is English
      textToSpeak = question.correctAnswer;
    }
    _ttsService.speak(textToSpeak);
  }

  void _handleAnswer(String option) async {
    // Logic updated to remove manual animation controller
    bool isCorrect = await _viewModel.answerQuestion(option);

    // Speak the word
    if (mounted && _viewModel.currentQuestion != null) {
      _speakQuestion(_viewModel.currentQuestion!);
    }

    // Auto move to next question after delay
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        if (!_viewModel.isFinished &&
            _viewModel.currentIndex < _viewModel.questions.length - 1) {
          _viewModel.nextQuestion();
        } else {
          _finishGame();
        }
      }
    });
  }

  Future<void> _finishGame() async {
    await _viewModel.submitResult();
    if (!mounted) return;
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showGameFinishDialog(
      context: context,
      correctCount: _viewModel.correctCount,
      wrongCount: _viewModel.wrongCount,
      onClose: () {
        Navigator.of(context).pop(); // close dialog
        Navigator.of(context).pop(); // back to selection
      },
      onReplay: () {
        Navigator.of(context).pop(); // close dialog
        _loadData();
      },
      wrongWordsCount: _viewModel.wrongQuestions.length,
      onRetryWrongWords:
          _viewModel.wrongQuestions.isNotEmpty
              ? () {
                Navigator.of(context).pop(); // close dialog
                _viewModel.startWrongQuestionsRetry();
              }
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                Theme.of(context).brightness == Brightness.dark
                    ? [
                      const Color(0xFF1E1E1E),
                     Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ]
                    : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
          ),
        ),
        child: Stack(
          children: [
            // Background decorations
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).primaryColor.withOpacity(0.3)
                          : Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: AnimatedBuilder(
                animation: _viewModel,
                builder: (context, child) {
                  if (_viewModel.isBusy) {
                    return CustomLoadingWidget(
                      message: 'Đang tải dữ liệu...',
                      color: Theme.of(context).colorScheme.primary,
                    );
                  }

                  if (_viewModel.errorMessage.isNotEmpty) {
                    return CustomErrorWidget(
                      errorMessage: _viewModel.errorMessage,
                      onRetry: _loadData,
                      onClose: () => Navigator.pop(context),
                    );
                  }

                  if (_viewModel.questions.isEmpty) {
                    return const Center(child: Text("Không có câu hỏi nào."));
                  }

                  final question = _viewModel.currentQuestion;
                  if (question == null) return const SizedBox();

                  return Column(
                    children: [
                      // Header
                      _buildHeader(),

                      // Progress Bar
                      _buildProgressBar(),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 20),
                              // Question Card
                              _buildQuestionCard(question),
                              const SizedBox(height: 40),

                              // Options
                              ...question.options.map(
                                (opt) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildOptionButton(
                                    opt,
                                    question.correctAnswer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Theme.of(context).cardColor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.1)
                      : Theme.of(context).cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.quiz_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Câu hỏi ${_viewModel.currentIndex + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Placeholder for balance or settings
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress =
        (_viewModel.currentIndex + 1) / _viewModel.questions.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        children: [
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 8,
            width:
                MediaQuery.of(context).size.width *
                0.8 *
                progress, // approx width
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestionV2 question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _speakQuestion(question),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volume_up_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question.word,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          if (question.phoneticText != null && widget.subType == 'en_vi')
            Text(
              question.phoneticText!,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          if (question.partOfSpeech != null &&
              question.partOfSpeech!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Colors.purple.withOpacity(0.1), // Purple/Pink tint
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                            : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Text(
                  question.partOfSpeech!,
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.primary
                            : Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option, String correctAnswer) {
    bool isSelected = option == _viewModel.selectedAnswer;
    bool isCorrect = option == correctAnswer;

    // UI State Logic
    Color bgColor =
        Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).cardColor
                .withRed(40)
                .withBlue(40) // Slight tint
            : Theme.of(context).cardColor;
    Color borderColor =
        Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
            : Theme.of(context).dividerColor;
    Color textColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        const Color(0xFF555555);
    IconData? icon;
    Color iconColor = Colors.transparent;

    if (_viewModel.isAnswered) {
      if (isCorrect) {
        bgColor = const Color(0xFFE8F5E9); // Light Green
        borderColor = Colors.green;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle_rounded;
        iconColor = Colors.green;
      } else if (isSelected) {
        bgColor = const Color(0xFFFFEBEE); // Light Red
        borderColor = Colors.red;
        textColor = Colors.red[800]!;
        icon = Icons.cancel_rounded;
        iconColor = Colors.red;
      } else {
        // Dim other options
        textColor = Colors.grey[400]!;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          if (!_viewModel.isAnswered)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _viewModel.isAnswered ? null : () => _handleAnswer(option),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, color: iconColor, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
