import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untitled/screens/reverse_quiz_screen.dart';
import 'package:untitled/screens/writing_game_screen.dart';
import '../api/auth_service.dart';
import '../api/tts_service.dart';

class QuizScreen extends StatefulWidget {
  final QuizSession session;
  const QuizScreen({Key? key, required this.session}) : super(key: key);

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  // --- STATE & LOGIC (GIỮ NGUYÊN HOÀN TOÀN) ---
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  List<int> _wrongAnswerVocabIds = [];
  String? _selectedAnswer;
  bool _isAnswered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final TextToSpeechService _ttsService = TextToSpeechService();

  QuizQuestion get currentQuestion => widget.session.questions[_currentIndex];

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200), vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ttsService.stop();
    _animationController.dispose();
    super.dispose();
  }

  void _handleAnswer(String selectedOption) {
    if (_isAnswered) return;
    _ttsService.speak(currentQuestion.word);
    setState(() {
      _isAnswered = true;
      _selectedAnswer = selectedOption;
      if (selectedOption == currentQuestion.correctAnswer) {
        _correctCount++;
      } else {
        _wrongCount++;
        _wrongAnswerVocabIds.add(currentQuestion.vocabularyId);
      }
    });

    Timer(const Duration(seconds: 2), () {
      if (_currentIndex < widget.session.questions.length - 1) {
        setState(() {
          _currentIndex++;
          _isAnswered = false;
          _selectedAnswer = null;
        });
      } else {
        _finishGame();
      }
    });
  }
  // --- HẾT PHẦN LOGIC ---


  // --- CÁC HẰNG SỐ VỀ GIAO DIỆN VÀ MÀU SẮC ---
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color accentPink = Color(0xFFFF80AB);
  static const Color backgroundPink = Color(0xFFFCE4EC);
  static const Color darkTextColor = Color(0xFF333333);
  static const Color correctColor = Colors.green;
  static const Color wrongColor = Colors.red;

  // --- CÁC WIDGET GIAO DIỆN ĐÃ ĐƯỢC THIẾT KẾ LẠI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Trắc nghiệm (${_currentIndex + 1}/${widget.session.questions.length})',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryPink, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Thanh tiến trình
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.session.questions.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 1),
                        _buildQuestionCard(),
                        const Spacer(flex: 1),
                        ...currentQuestion.options.map((option) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: _buildAnswerButton(option),
                          );
                        }).toList(),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        width: double.infinity,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Column(
            key: ValueKey<int>(_currentIndex),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currentQuestion.word,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: darkTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (currentQuestion.phoneticText != null && currentQuestion.phoneticText!.isNotEmpty)
                Text(
                  currentQuestion.phoneticText!,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 18, fontStyle: FontStyle.italic),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String option) {
    bool isCorrect = option == currentQuestion.correctAnswer;
    bool isSelected = option == _selectedAnswer;
    Color buttonColor;
    Color textColor;
    Widget? icon;

    if (_isAnswered) {
      if (isCorrect) {
        buttonColor = correctColor;
        textColor = Colors.white;
      } else if (isSelected) {
        buttonColor = wrongColor;
        textColor = Colors.white;
      } else {
        buttonColor = Colors.white.withOpacity(0.5);
        textColor = darkTextColor.withOpacity(0.5);
      }
    } else {
      buttonColor = Colors.white;
      textColor = primaryPink;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: ElevatedButton(
        onPressed: _isAnswered ? null : () {
          _animationController.forward().then((_) {
            _animationController.reverse();
            _handleAnswer(option);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          disabledBackgroundColor: buttonColor,
          disabledForegroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 20),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 8)],
            Expanded(child: Text(option, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }

  Future<void> _finishGame() async {
    // Logic cập nhật kết quả không đổi
    try {
      await AuthService.updateGameResult(widget.session.gameResultId, _correctCount, _wrongCount, _wrongAnswerVocabIds);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: wrongColor));
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              const Icon(Icons.celebration, color: primaryPink, size: 28),
              const SizedBox(width: 8),
              Text('Hoàn thành!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: primaryPink)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kết quả của bạn:', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: darkTextColor)),
              const SizedBox(height: 16),
              _buildResultRow(Icons.check, 'Đúng: $_correctCount', correctColor),
              const SizedBox(height: 8),
              _buildResultRow(Icons.close, 'Sai: $_wrongCount', wrongColor),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                int count = 0;
                Navigator.of(ctx).popUntil((_) => count++ >= 2);
              },
              child: const Text('OK', style: TextStyle(color: primaryPink)),
            ),
            if (_wrongCount > 0)
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primaryPink)));
                    final newSession = await AuthService.startRetryGame(widget.session.gameResultId);
                    if (mounted) {
                      Navigator.pop(context);
                      if (newSession is QuizSession) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizScreen(session: newSession)));
                      else if (newSession is ReverseQuizSession) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReverseQuizScreen(session: newSession)));
                      else if (newSession is GameSession) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WritingGameScreen(session: newSession)));
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}'), backgroundColor: wrongColor));
                    }
                  }
                },
                icon: const Icon(Icons.replay_circle_filled),
                label: const Text('Ôn tập lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget _buildResultRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}