import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:untitled/screens/quiz_screen.dart';
import 'package:untitled/screens/writing_game_screen.dart';
import '../api/auth_service.dart';
import '../api/tts_service.dart';

class ReverseQuizScreen extends StatefulWidget {
  final ReverseQuizSession session;
  const ReverseQuizScreen({Key? key, required this.session}) : super(key: key);

  @override
  _ReverseQuizScreenState createState() => _ReverseQuizScreenState();
}

class _ReverseQuizScreenState extends State<ReverseQuizScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  List<int> _wrongAnswerVocabIds = [];
  String? _selectedAnswer;
  bool _isAnswered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final TextToSpeechService _ttsService = TextToSpeechService();
  ReverseQuizQuestion get currentQuestion => widget.session.questions[_currentIndex];

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ttsService.stop();
    _animationController.dispose();
    super.dispose();
  }

  void _handleAnswer(String selectedOption) {
    if (_isAnswered) return;
    _ttsService.speak(currentQuestion.correctAnswer);
    setState(() {
      _isAnswered = true;
      _selectedAnswer = selectedOption;
      if (selectedOption == currentQuestion.correctAnswer) _correctCount++;
      else {
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


  static const Color primaryPink = Color(0xFFE91E63);
  static const Color accentPink = Color(0xFFFF80AB);
  static const Color darkTextColor = Color(0xFF333333);
  static const Color correctColor = Colors.green;
  static const Color wrongColor = Colors.red;


  void _showFullMeaningDialog(String meaning) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.description_outlined, color: primaryPink),
            SizedBox(width: 10),
            Text("Nghĩa đầy đủ", style: TextStyle(color: darkTextColor)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            meaning,
            style: const TextStyle(fontSize: 18, height: 1.5, color: darkTextColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: primaryPink)),
          ),
        ],
      ),
    );
  }


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
                child: LayoutBuilder(builder: (context, constraints) {
                  return constraints.maxWidth > 700 ? _buildWideLayout() : _buildNarrowLayout();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Expanded(flex: 1, child: _buildImageArea()),
          const SizedBox(height: 24),
          Expanded(flex: 3, child: _buildControlsArea()),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Row(
        children: [
          Expanded(flex: 2, child: _buildImageArea()),
          const SizedBox(width: 80),
          Expanded(flex: 2, child: _buildControlsArea()),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: (currentQuestion.userImageBase64 != null && currentQuestion.userImageBase64!.isNotEmpty)
            ? Image.memory(
          base64Decode(currentQuestion.userImageBase64!),
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => _buildImagePlaceholder(),
        )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 80),
      ),
    );
  }

  Widget _buildControlsArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildQuestionCard(),
        const SizedBox(height: 24),
        ...currentQuestion.options.map((option) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: _buildAnswerButton(option),
        )),
      ],
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: GestureDetector(
        onTap: () {
          _showFullMeaningDialog(currentQuestion.userDefinedMeaning);
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: Text(
            key: ValueKey<int>(_currentIndex),
            currentQuestion.userDefinedMeaning,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1, 1))],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String option) {
    bool isCorrect = option == currentQuestion.correctAnswer;
    bool isSelected = option == _selectedAnswer;
    Color buttonColor, textColor;
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
          padding: const EdgeInsets.symmetric(vertical: 22),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon, const SizedBox(width: 8)],
            Expanded(child: Text(option, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Future<void> _finishGame() async {
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