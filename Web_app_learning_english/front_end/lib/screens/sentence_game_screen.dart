import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

// Vui lòng đảm bảo các đường dẫn này đúng với dự án của bạn
import 'package:untitled/api/auth_service.dart';
import 'package:untitled/api/tts_service.dart';
import 'package:untitled/screens/quiz_screen.dart';
import 'package:untitled/screens/reverse_quiz_screen.dart';

enum FeedbackState { initial, loading, correct, incorrect }

class SentenceGameScreen extends StatefulWidget {
  final GameSession session;
  const SentenceGameScreen({Key? key, required this.session}) : super(key: key);

  @override
  _SentenceGameScreenState createState() => _SentenceGameScreenState();
}

class _SentenceGameScreenState extends State<SentenceGameScreen> {
  final _nextButtonFocusNode = FocusNode();
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  List<int> _wrongAnswerVocabIds = [];
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitted = false;
  FeedbackState _feedbackState = FeedbackState.initial;
  String _feedbackMessage = '';
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _showUserAnswerInFeedback = false;

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
    // <<< THAY ĐỔI: Hủy FocusNode để tránh rò rỉ bộ nhớ
    _nextButtonFocusNode.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _checkAnswer() async {
    if (_isSubmitted || _textController.text.trim().isEmpty) return;
    _ttsService.speak(currentVocab.word);
    setState(() {
      _isSubmitted = true;
      _feedbackState = FeedbackState.loading;
    });

    try {
      final response = await AuthService.checkWritingSentence(currentVocab.id, _textController.text.trim());
      if (mounted) {
        setState(() {
          _feedbackMessage = response.feedback;
          _feedbackState = response.isCorrect ? FeedbackState.correct : FeedbackState.incorrect;
          if (response.isCorrect) _correctCount++;
          else {
            _wrongCount++;
            _wrongAnswerVocabIds.add(currentVocab.id);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _feedbackState = FeedbackState.incorrect;
          _feedbackMessage = 'Đã xảy ra lỗi kết nối. Vui lòng thử lại.';
          _wrongCount++;
          if (!_wrongAnswerVocabIds.contains(currentVocab.id)) _wrongAnswerVocabIds.add(currentVocab.id);
        });
      }
    }

    // <<< THAY ĐỔI: Sau khi nhận được kết quả (thành công hoặc lỗi),
    // đợi frame tiếp theo render rồi chuyển focus đến nút "Tiếp theo".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nextButtonFocusNode.requestFocus();
      }
    });
  }

  void _nextWord() {
    if (_currentIndex < widget.session.vocabularies.length - 1) {
      setState(() {
        _currentIndex++;
        _isSubmitted = false;
        _feedbackState = FeedbackState.initial;
        _feedbackMessage = '';
        _textController.clear();
        _showUserAnswerInFeedback = false;
      });
      Future.delayed(Duration.zero, () => _focusNode.requestFocus());
    } else {
      _finishGame();
    }
  }

  // --- CÁC HẰNG SỐ VỀ GIAO DIỆN VÀ MÀU SẮC ---
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color accentPink = Color(0xFFFF80AB);
  static const Color backgroundPink = Color(0xFFFCE4EC);
  static const Color darkTextColor = Color(0xFF333333);
  static const Color correctColor = Colors.green;
  static const Color wrongColor = Colors.red;

  // --- CÁC DIALOGS ---
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
        else if (newSession is GameSession) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SentenceGameScreen(session: newSession)));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi bắt đầu ôn tập: ${e.toString()}')));
      }
    }
  }

  // --- CÁC WIDGET GIAO DIỆN ---
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundPink,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('Đặt câu (${_currentIndex + 1}/${widget.session.vocabularies.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true, elevation: 0,
          backgroundColor: primaryPink, foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _onWillPop()) {
                if(mounted) Navigator.of(context).pop();
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
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                          child: Column(
                            key: ValueKey<int>(_currentIndex),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (currentVocab.userImageBase64?.isNotEmpty ?? false)
                                Flexible(child: _buildImageCard(currentVocab.userImageBase64!)),
                              const SizedBox(height: 20),
                              _buildQuestionCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInputField(),
                    if (currentVocab.userDefinedMeaning?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          'Gợi ý: "${currentVocab.userDefinedMeaning}"',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ),
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
      elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentVocab.word,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryPink),
                textAlign: TextAlign.center,
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
    return ConstrainedBox(constraints: BoxConstraints(maxWidth: 600),
      child: TextField(
        controller: _textController, focusNode: _focusNode,
        enabled: !_isSubmitted,
        decoration: InputDecoration(
          hintText: 'Viết câu của bạn ở đây...',
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryPink, width: 2),
          ),
        ),
        onSubmitted: (_) => _feedbackState == FeedbackState.loading ? null : (_isSubmitted ? _nextWord() : _checkAnswer()),
        maxLines: 3, minLines: 1,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _buildFooter() {
    bool showFeedback = _isSubmitted && _feedbackState != FeedbackState.initial;
    Color feedbackColor = Colors.transparent;
    Widget feedbackWidget = const SizedBox.shrink();

    if (showFeedback) {
      switch (_feedbackState) {
        case FeedbackState.loading:
          feedbackWidget = const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: CircularProgressIndicator(color: primaryPink, key: ValueKey('loading')),
          ));
          break;
        case FeedbackState.correct:
          feedbackColor = correctColor.withOpacity(0.1);
          feedbackWidget = _buildFeedbackContent(icon: Icons.check_circle, color: correctColor, title: 'Tuyệt vời!', subtitle: _feedbackMessage);
          break;
        case FeedbackState.incorrect:
          feedbackColor = wrongColor.withOpacity(0.1);
          feedbackWidget = _buildFeedbackContent(icon: Icons.cancel, color: wrongColor, title: 'Gợi ý cho bạn', subtitle: _feedbackMessage);
          break;
        default:
          break;
      }
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
            child: showFeedback
                ? Container(
              key: ValueKey(_feedbackState),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(color: feedbackColor, borderRadius: BorderRadius.circular(16)),
              child: feedbackWidget,
            )
                : const SizedBox.shrink(key: ValueKey('empty_box')),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              // <<< THAY ĐỔI: Gán FocusNode vào nút
              focusNode: _nextButtonFocusNode,
              onPressed: _feedbackState == FeedbackState.loading ? null : (_isSubmitted ? _nextWord : _checkAnswer),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: _isSubmitted ? (_feedbackState == FeedbackState.correct ? correctColor : wrongColor) : primaryPink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: Text(_isSubmitted ? 'Tiếp theo' : 'Kiểm tra'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackContent({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Column(
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
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: darkTextColor, fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 20, thickness: 1),
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
                  'Xem câu của bạn',
                  style: TextStyle(color: darkTextColor.withOpacity(0.8), fontWeight: FontWeight.w500),
                ),
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
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _textController.text.trim().isEmpty ? '(Bạn chưa viết câu)' : _textController.text.trim(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: darkTextColor),
            ),
          )
              : const SizedBox(width: double.infinity),
        ),
      ],
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