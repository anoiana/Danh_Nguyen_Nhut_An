import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/tts_service.dart';
import '../view_model/writing_view_model.dart';
import '../../Vocabulary/model/vocabulary.dart';

class WritingView extends StatefulWidget {
  final int folderId;
  final String folderName;

  const WritingView({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<WritingView> createState() => _WritingViewState();
}

class _WritingViewState extends State<WritingView> {
  final WritingViewModel _viewModel = WritingViewModel();
  final TextToSpeechService _ttsService = TextToSpeechService();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _nextButtonFocusNode = FocusNode();

  // Colors
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color correctColor = Colors.green;
  static const Color wrongColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _loadData();
    _ttsService.init();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      await _viewModel.init(userId, widget.folderId);
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    _viewModel.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _nextButtonFocusNode.dispose();
    super.dispose();
  }

  void _checkAnswer() async {
    if (_textController.text.trim().isEmpty) return;
    if (_viewModel.currentVocabulary == null) return;

    bool isCorrect = await _viewModel.checkAnswer(_textController.text);
    if (mounted && _viewModel.currentVocabulary != null) {
      await _ttsService.setSpeechRate(0.5);
      _ttsService.speak(_viewModel.currentVocabulary!.word);
    }

    // Auto focus next button
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nextButtonFocusNode.requestFocus();
    });
  }

  void _nextWord() {
    if (!_viewModel.isFinished &&
        _viewModel.currentIndex < _viewModel.vocabularies.length - 1) {
      _viewModel.nextQuestion();
      _textController.clear();
      // Focus back to input
      Future.delayed(Duration.zero, () => _focusNode.requestFocus());
    } else {
      _finishGame();
    }
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
                  'Kết quả: ${_viewModel.correctCount}/${_viewModel.vocabularies.length}',
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
                  Navigator.pop(ctx);
                  Navigator.pop(context);
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
                  _textController.clear();
                  _focusNode.requestFocus();
                },
              ),
              if (_viewModel.wrongVocabularies.isNotEmpty)
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
                      _viewModel.startWrongWordsRetry();
                      _textController.clear();
                      _focusNode.requestFocus();
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
      resizeToAvoidBottomInset: true, // Allow resize for keyboard
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
              top: -80,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
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
                  if (_viewModel.vocabularies.isEmpty) {
                    return const Center(child: Text('Không có từ vựng.'));
                  }

                  final vocab = _viewModel.currentVocabulary!;

                  return Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 24),
                                    _buildQuestionCard(vocab),
                                    const SizedBox(height: 32),
                                    _buildInputField(),
                                    const SizedBox(height: 250),
                                  ],
                                ),
                              ),
                            );
                          },
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
      bottomSheet: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, child) {
          if (_viewModel.vocabularies.isEmpty) return const SizedBox.shrink();
          return _buildFooter(_viewModel.currentVocabulary!);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: primaryPink),
                ),
                onPressed: () => Navigator.pop(context),
              ),

              Text(
                'Câu ${_viewModel.currentIndex + 1}/${_viewModel.vocabularies.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryPink,
                ),
              ),

              const SizedBox(width: 48), // Balance for back button
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:
                  (_viewModel.currentIndex + 1) /
                  _viewModel.vocabularies.length,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Vocabulary vocab) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32), // Rounder corners
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Định nghĩa',
              style: TextStyle(
                color: primaryPink.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            vocab.userDefinedMeaning ?? '(Chưa có nghĩa)',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800, // Bolder
              color: Color(0xFF333333),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (vocab.meanings?.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    vocab.meanings!.first.partOfSpeech ?? 'Word',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _ttsService.speak(vocab.word),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryPink.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: primaryPink,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: !_viewModel.isSubmitted,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: primaryPink,
        ),
        decoration: InputDecoration(
          hintText: 'Nhập từ tiếng Anh...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 18),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 24,
            horizontal: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(40),
            borderSide: const BorderSide(color: primaryPink, width: 2),
          ),
        ),
        onSubmitted:
            (_) => _viewModel.isSubmitted ? _nextWord() : _checkAnswer(),
      ),
    );
  }

  Widget _buildFooter(Vocabulary vocab) {
    bool showFeedback = _viewModel.isSubmitted;
    Color color =
        _viewModel.feedbackState == FeedbackState.correct
            ? correctColor
            : wrongColor;
    String title =
        _viewModel.feedbackState == FeedbackState.correct
            ? 'Chính xác! 🎉'
            : 'Opps! Chưa đúng rồi 💪';
    String subtitle =
        _viewModel.feedbackState == FeedbackState.correct
            ? 'Bạn giỏi quá!'
            : 'Đáp án là: ${vocab.word}';
    IconData icon =
        _viewModel.feedbackState == FeedbackState.correct
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 25,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder:
                (child, animation) =>
                    SizeTransition(sizeFactor: animation, child: child),
            child:
                showFeedback
                    ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    : const SizedBox.shrink(),
          ),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              focusNode: _nextButtonFocusNode,
              onPressed: _viewModel.isSubmitted ? _nextWord : _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: _viewModel.isSubmitted ? color : primaryPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 4,
                shadowColor: (_viewModel.isSubmitted ? color : primaryPink)
                    .withOpacity(0.4),
              ),
              child: Text(
                _viewModel.isSubmitted ? 'TIẾP THEO' : 'KIỂM TRA',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
