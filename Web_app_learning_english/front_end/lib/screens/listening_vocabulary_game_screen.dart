// lib/screens/listening_vocabulary_game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:untitled/screens/quiz_screen.dart';
import 'package:untitled/screens/reverse_quiz_screen.dart';
import 'package:untitled/screens/sentence_game_screen.dart';
// Bỏ import không dùng đến
// import 'package:untitled/screens/sentence_game_screen.dart';
import '../api/auth_service.dart';
import '../api/tts_service.dart';

class ListeningVocabularyGameScreen extends StatefulWidget {
  final GameSession session;
  const ListeningVocabularyGameScreen({Key? key, required this.session}) : super(key: key);

  @override
  _ListeningVocabularyGameScreenState createState() => _ListeningVocabularyGameScreenState();
}

class _ListeningVocabularyGameScreenState extends State<ListeningVocabularyGameScreen> {
  // --- Các biến trạng thái và logic không thay đổi ---
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  final List<int> _wrongAnswerVocabIds = [];
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _nextButtonFocusNode = FocusNode();
  bool _isSubmitted = false;
  FeedbackState _feedbackState = FeedbackState.initial;
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _showUserAnswerInFeedback = false;

  Vocabulary get currentVocab => widget.session.vocabularies[_currentIndex];

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _playCurrentWordSound();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _nextButtonFocusNode.dispose();
    _ttsService.stop();
    super.dispose();
  }

  // --- Các hàm logic và helper không thay đổi ---
  void _playCurrentWordSound() {
    _ttsService.speak(currentVocab.word);
  }

  void _checkAnswer() {
    if (_isSubmitted || _textController.text.trim().isEmpty) return;
    final userAnswer = _textController.text.trim().toLowerCase();
    final correctAnswer = currentVocab.word.trim().toLowerCase();
    setState(() {
      _isSubmitted = true;
      if (userAnswer == correctAnswer) {
        _correctCount++;
        _feedbackState = FeedbackState.correct;
      } else {
        _wrongCount++;
        _wrongAnswerVocabIds.add(currentVocab.id);
        _feedbackState = FeedbackState.incorrect;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nextButtonFocusNode.requestFocus();
    });
  }

  void _nextWord() {
    _showUserAnswerInFeedback = false;
    if (_currentIndex < widget.session.vocabularies.length - 1) {
      setState(() {
        _currentIndex++;
        _isSubmitted = false;
        _feedbackState = FeedbackState.initial;
        _textController.clear();
      });
      Future.delayed(Duration.zero, () {
        _focusNode.requestFocus();
        _playCurrentWordSound();
      });
    } else {
      _finishGame();
    }
  }

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color accentPink = Color(0xFFFF80AB);
  static const Color backgroundPink = Color(0xFFFCE4EC);
  static const Color darkTextColor = Color(0xFF333333);
  static const Color correctColor = Colors.green;
  static const Color wrongColor = Colors.red;

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.exit_to_app, color: primaryPink), SizedBox(width: 8), Text('Xác nhận thoát')]),
        content: const Text('Bạn có chắc chắn muốn thoát? Tiến trình chơi sẽ không được lưu lại.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Ở lại')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: wrongColor, foregroundColor: Colors.white),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  Future<void> _finishGame() async {
    try {
      await AuthService.updateGameResult(widget.session.gameResultId, _correctCount, _wrongCount, _wrongAnswerVocabIds);
    } catch (e) {
      debugPrint("Lỗi cập nhật kết quả game: $e");
    }
    if (mounted) {
      showDialog(
        context: context, barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(Icons.celebration, color: primaryPink), SizedBox(width: 8), Text('Hoàn thành!')]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Kết quả của bạn:'),
            const SizedBox(height: 16),
            _buildResultRow(Icons.check, 'Đúng: $_correctCount', correctColor),
            const SizedBox(height: 8),
            _buildResultRow(Icons.close, 'Sai: $_wrongCount', wrongColor),
          ]),
          actions: [
            TextButton(
              onPressed: () { int count = 0; Navigator.of(ctx).popUntil((_) => count++ >= 2); },
              child: const Text('Về màn hình chính'),
            ),
            if (_wrongCount > 0)
              ElevatedButton.icon(
                onPressed: () { Navigator.of(ctx).pop(); _retryWrongAnswers(); },
                icon: const Icon(Icons.replay),
                label: const Text('Ôn tập lại'),
                style: ElevatedButton.styleFrom(backgroundColor: primaryPink, foregroundColor: Colors.white),
              ),
          ],
        ),
      );
    }
  }

  Future<void> _retryWrongAnswers() async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: primaryPink)));
      final newSession = await AuthService.startRetryGame(widget.session.gameResultId);
      if (mounted) {
        Navigator.pop(context);
        if (newSession is QuizSession) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizScreen(session: newSession)));
        else if (newSession is ReverseQuizSession) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ReverseQuizScreen(session: newSession)));
        else if (newSession is GameSession) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ListeningVocabularyGameScreen(session: newSession)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi bắt đầu ôn tập: ${e.toString()}')));
      }
    }
  }

  // --- BUILD METHOD & WIDGETS ---
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundPink,
        resizeToAvoidBottomInset: true, // Đảm bảo Scaffold co lại khi bàn phím hiện
        appBar: AppBar(
          title: Text(
            'Nghe & Viết (${_currentIndex + 1}/${widget.session.vocabularies.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.session.vocabularies.length,
              backgroundColor: accentPink.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        bottomSheet: _buildFooter(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(scale: animation, child: child),
                          ),
                          child: Column(
                            key: ValueKey<int>(_currentIndex),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildQuestionContent(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(),
                    const SizedBox(height: 120), // Vùng đệm cho bottomsheet
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionContent() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nghe và điền từ đúng',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: _playCurrentWordSound,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryPink.withOpacity(0.1),
                  border: Border.all(color: primaryPink, width: 2),
                ),
                child: const Icon(Icons.volume_up, color: primaryPink, size: 50),
              ),
            ),
            if (_isSubmitted && _feedbackState == FeedbackState.incorrect && (currentVocab.userDefinedMeaning?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  'Gợi ý: ${currentVocab.userDefinedMeaning}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic, color: darkTextColor.withOpacity(0.8)),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: !_isSubmitted,
        decoration: InputDecoration(
          hintText: 'Nhập từ bạn nghe được...',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryPink, width: 2),
          ),
        ),
        onSubmitted: (_) => _isSubmitted ? _nextWord() : _checkAnswer(),
      ),
    );
  }

  Widget _buildFooter() {
    bool showFeedback = _isSubmitted && _feedbackState != FeedbackState.initial;
    Widget feedbackWidget;
    if (showFeedback) {
      if (_feedbackState == FeedbackState.correct) {
        feedbackWidget = _buildFeedbackContent(
          icon: Icons.check_circle,
          color: correctColor,
          title: 'Chính xác!',
          // <<< ĐIỀU CHỈNH: Không cần hiển thị đáp án nữa vì nó sẽ được hiển thị bên dưới >>>
        );
      } else {
        feedbackWidget = _buildFeedbackContent(
          icon: Icons.cancel,
          color: wrongColor,
          title: 'Chưa đúng!',
        );
      }
    } else {
      feedbackWidget = const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => SizeTransition(sizeFactor: animation, child: child),
            child: showFeedback ? feedbackWidget : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              focusNode: _nextButtonFocusNode,
              onPressed: _isSubmitted ? _nextWord : _checkAnswer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: _isSubmitted ? (_feedbackState == FeedbackState.correct ? correctColor : wrongColor) : primaryPink,
                foregroundColor: Colors.white,
              ),
              child: Text(_isSubmitted ? 'Tiếp theo' : 'Kiểm tra'),
            ),
          ),
        ],
      ),
    );
  }

  // <<< ĐÂY LÀ PHƯƠNG THỨC ĐƯỢC CẬP NHẬT CHÍNH >>>
  Widget _buildFeedbackContent({required IconData icon, required Color color, required String title}) {
    Color feedbackBackgroundColor = color.withOpacity(0.1);

    return Container(
      key: const ValueKey('feedback_box'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: feedbackBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 6),
                    // <<< THÊM VÀO: Hiển thị từ đúng >>>
                    Text(
                      'Đáp án: ${currentVocab.word}',
                      style: const TextStyle(color: darkTextColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // <<< THÊM VÀO: Hiển thị nghĩa tiếng Việt nếu có >>>
                    if (currentVocab.userDefinedMeaning?.isNotEmpty ?? false)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              currentVocab.userDefinedMeaning!, // Dùng ! vì đã kiểm tra isNotEmpty
                              style: TextStyle(
                                fontSize: 16,
                                color: darkTextColor.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          // Giữ nguyên phần xem lại câu trả lời của người dùng
          const Divider(height: 20, thickness: 1),
          InkWell(
            onTap: () => setState(() => _showUserAnswerInFeedback = !_showUserAnswerInFeedback),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Xem câu trả lời của bạn', style: TextStyle(color: darkTextColor.withOpacity(0.8), fontWeight: FontWeight.w500)),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _showUserAnswerInFeedback ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down, color: darkTextColor.withOpacity(0.8)),
                  )
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showUserAnswerInFeedback
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Text(_textController.text.trim(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkTextColor)),
            )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(IconData icon, String text, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
    ]);
  }
}