import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:untitled/screens/quiz_screen.dart';
import 'package:untitled/screens/reverse_quiz_screen.dart';
import '../api/auth_service.dart';
import '../api/tts_service.dart';

// Enum không thay đổi
enum FeedbackState { initial, correct, incorrect }

class WritingGameScreen extends StatefulWidget {
  final GameSession session;
  const WritingGameScreen({Key? key, required this.session}) : super(key: key);

  @override
  _WritingGameScreenState createState() => _WritingGameScreenState();
}

class _WritingGameScreenState extends State<WritingGameScreen> {
  bool _showUserAnswerInFeedback = false;
  final _nextButtonFocusNode = FocusNode();
  // --- STATE & LOGIC (GIỮ NGUYÊN HOÀN TOÀN) ---
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  List<int> _wrongAnswerVocabIds = [];
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitted = false;
  FeedbackState _feedbackState = FeedbackState.initial;
  final TextToSpeechService _ttsService = TextToSpeechService();
  Vocabulary get currentVocab => widget.session.vocabularies[_currentIndex];
  String get partOfSpeech => (currentVocab.meanings?.isNotEmpty ?? false) ? currentVocab.meanings!.first.partOfSpeech : '';

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _nextButtonFocusNode.dispose();
    _ttsService.stop();
    super.dispose();
  }

  void _checkAnswer() {
    if (_isSubmitted || _textController.text.trim().isEmpty) return;
    _ttsService.speak(currentVocab.word);
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

    // <<< THAY ĐỔI: Yêu cầu focus vào nút "Tiếp theo" sau khi UI đã cập nhật
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nextButtonFocusNode.requestFocus();
    });
  }

  void _nextWord() {
    if (_currentIndex < widget.session.vocabularies.length - 1) {
      setState(() {
        _currentIndex++;
        _isSubmitted = false;
        _feedbackState = FeedbackState.initial;
        _textController.clear();
      });
      Future.delayed(Duration.zero, () => _focusNode.requestFocus());
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
        else if (newSession is GameSession) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WritingGameScreen(session: newSession)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi bắt đầu ôn tập: ${e.toString()}')));
      }
    }
  }

  void _showFullMeaningDialog(String meaning) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.description_outlined, color: primaryPink),
            SizedBox(width: 10),
            Text("Nghĩa đầy đủ"),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            meaning,
            style: const TextStyle(fontSize: 18, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundPink,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            'Viết Từ (${_currentIndex + 1}/${widget.session.vocabularies.length})',
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
            padding: const EdgeInsets.symmetric(horizontal: 20.0), // Padding ngang
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600), // Giới hạn chiều rộng tối đa của toàn bộ nội dung
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
                              if (currentVocab.userImageBase64?.isNotEmpty ?? false)
                                Flexible(
                                  child: _buildImageCard(currentVocab.userImageBase64!),
                                ),
                              const SizedBox(height: 20),
                              _buildQuestionCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(String base64Image) {
    return Card(
      elevation: 6, shadowColor: primaryPink.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: Image.memory(
          base64Decode(base64Image),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (c, e, s) => _buildImagePlaceholder(),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 180,
      decoration: BoxDecoration(color: Colors.grey.shade200),
      child: Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade400, size: 50)),
    );
  }

  Widget _buildQuestionCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Giới hạn chiều rộng tối đa
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (currentVocab.userDefinedMeaning != null &&
                      currentVocab.userDefinedMeaning!.isNotEmpty) {
                    _showFullMeaningDialog(currentVocab.userDefinedMeaning!);
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: Text(
                    currentVocab.userDefinedMeaning ?? '(Chưa có nghĩa)',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: darkTextColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (partOfSpeech.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: accentPink.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(partOfSpeech, style: const TextStyle(color: primaryPink, fontWeight: FontWeight.w600)),
                    ),
                  if (partOfSpeech.isNotEmpty && (currentVocab.phoneticText?.isNotEmpty ?? false)) const SizedBox(width: 12),
                  if (currentVocab.phoneticText?.isNotEmpty ?? false)
                    Text(currentVocab.phoneticText!, style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
                  const SizedBox(width: 12),
                  IconButton(onPressed: () => _ttsService.speak(currentVocab.word), icon: const Icon(Icons.volume_up, color: primaryPink, size: 28)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600), // Giới hạn chiều rộng tối đa
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: !_isSubmitted,
        decoration: InputDecoration(
          hintText: 'Nhập từ tiếng Anh...',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryPink, width: 2),
          ),
        ),
        onSubmitted: (_) => _isSubmitted ? _nextWord : _checkAnswer(),
      ),
    );
  }

  Widget _buildFooter() {
    bool showFeedback = _isSubmitted && _feedbackState != FeedbackState.initial;

    // Lấy ra nội dung feedback tương ứng
    Widget feedbackWidget;
    if (showFeedback) {
      if (_feedbackState == FeedbackState.correct) {
        feedbackWidget = _buildFeedbackContent(
          icon: Icons.check_circle,
          color: correctColor,
          title: 'Chính xác!',
          subtitle: 'Làm tốt lắm!',
        );
      } else {
        feedbackWidget = _buildFeedbackContent(
          icon: Icons.cancel,
          color: wrongColor,
          title: 'Chưa đúng!',
          subtitle: 'Đáp án đúng là: ${currentVocab.word}',
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
          // Widget này sẽ co giãn mượt mà
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SizeTransition(sizeFactor: animation, child: child);
            },
            // Dùng key để AnimatedSwitcher nhận biết sự thay đổi giữa có và không có feedback
            child: showFeedback ? feedbackWidget : const SizedBox.shrink(key: ValueKey('empty')),
          ),

          // Nút bấm không đổi
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              focusNode: _nextButtonFocusNode, // <<< THAY ĐỔI: Gán FocusNode vào nút
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

  Widget _buildFeedbackContent({required IconData icon, required Color color, required String title, required String subtitle}) {
    Color feedbackBackgroundColor = color.withOpacity(0.1);

    return Container(
      key: const ValueKey('feedback_box'), // Key cho AnimatedSwitcher
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: feedbackBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 1. Phần feedback chính (không đổi)
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
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: darkTextColor, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),

          // 2. Đường kẻ ngăn cách
          const Divider(height: 20, thickness: 1),

          // 3. Nút bấm để xổ câu trả lời xuống
          InkWell(
            onTap: () {
              setState(() {
                _showUserAnswerInFeedback = !_showUserAnswerInFeedback;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Xem câu trả lời của bạn',
                    style: TextStyle(color: darkTextColor.withOpacity(0.8), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _showUserAnswerInFeedback ? 0.5 : 0, // 0.5 turns = 180 độ
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.keyboard_arrow_down, color: darkTextColor.withOpacity(0.8)),
                  )
                ],
              ),
            ),
          ),

          // 4. Phần hiển thị câu trả lời (co giãn mượt mà)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showUserAnswerInFeedback
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _textController.text.trim(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkTextColor),
              ),
            )
                : const SizedBox(width: double.infinity), // Bắt buộc phải có để AnimatedSize hoạt động
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