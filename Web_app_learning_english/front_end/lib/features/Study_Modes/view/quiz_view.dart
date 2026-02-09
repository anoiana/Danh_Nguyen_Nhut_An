import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/tts_service.dart';
import '../view_model/quiz_view_model.dart';
import '../model/quiz_session.dart';

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
  static const Color primaryPink = Color(0xFFE91E63);
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

  void _handleAnswer(String option) async {
    // Logic updated to remove manual animation controller
    bool isCorrect = await _viewModel.answerQuestion(option);

    // Speak the word
    if (mounted && _viewModel.currentQuestion != null) {
      await _ttsService.setSpeechRate(0.5);

      String textToSpeak = _viewModel.currentQuestion!.word;
      // If mode is Vietnamese -> English, the 'word' is the Vietnamese definition.
      // We want to speak the English answer instead.
      if (widget.subType == 'vi_en') {
        textToSpeak = _viewModel.currentQuestion!.correctAnswer;
      }

      _ttsService.speak(textToSpeak);
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.celebration, color: primaryPink),
                SizedBox(width: 8),
                Text('Hoàn thành!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Kết quả: ${_viewModel.correctCount}/${_viewModel.questions.length}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.check, color: correctColor),
                    Text('Đúng: ${_viewModel.correctCount}'),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.close, color: wrongColor),
                    Text('Sai: ${_viewModel.wrongCount}'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Đóng'),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Back to selection
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Luyện tập lại'),
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  _loadData(); // Reload data/reset state
                },
              ),
              if (_viewModel.wrongQuestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ôn tập từ sai'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _viewModel.startWrongQuestionsRetry();
                    },
                  ),
                ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
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
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: AnimatedBuilder(
                animation: _viewModel,
                builder: (context, child) {
                  if (_viewModel.isBusy) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryPink),
                    );
                  }

                  if (_viewModel.errorMessage.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.orange,
                            size: 60,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Lỗi: ${_viewModel.errorMessage}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Quay lại'),
                          ),
                        ],
                      ),
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
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: primaryPink),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.quiz_rounded, color: primaryPink, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Câu hỏi ${_viewModel.currentIndex + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryPink,
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
              color: Colors.white.withOpacity(0.5),
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
              color: primaryPink,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: primaryPink.withOpacity(0.4),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: primaryPink,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            question.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          if (question.phoneticText != null)
            Text(
              question.phoneticText!,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Chọn nghĩa đúng',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option, String correctAnswer) {
    bool isSelected = option == _viewModel.selectedAnswer;
    bool isCorrect = option == correctAnswer;

    // UI State Logic
    Color bgColor = Colors.white;
    Color borderColor = Colors.transparent;
    Color textColor = const Color(0xFF555555);
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
