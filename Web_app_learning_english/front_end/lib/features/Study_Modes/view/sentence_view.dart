import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_model/sentence_view_model.dart';

class SentenceView extends StatefulWidget {
  final int folderId;
  final String folderName;

  const SentenceView({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<SentenceView> createState() => _SentenceViewState();
}

class _SentenceViewState extends State<SentenceView> {
  final SentenceViewModel _viewModel = SentenceViewModel();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _nextButtonFocusNode = FocusNode();
  bool _showUserAnswerInFeedback = false;
  bool _isFinishDialogShown = false;

  // Colors
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color correctColor = Colors.green;
  static const Color wrongColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _viewModel.setBusy(true);
    _initGame();
  }

  Future<void> _initGame() async {
    _isFinishDialogShown = false;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId != null) {
      await _viewModel.init(userId, widget.folderId);
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _nextButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<SentenceViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isBusy) {
            return Scaffold(
              body: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryPink),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải dữ liệu...',
                      style: TextStyle(
                        color: primaryPink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (viewModel.isError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Lỗi')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(viewModel.errorMessage),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initGame,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (viewModel.session == null) {
            return const Scaffold(
              body: Center(child: Text("Không tìm thấy dữ liệu trò chơi.")),
            );
          }

          // Game Finished logic
          if (viewModel.currentIndex >=
              viewModel.session!.vocabularies.length) {
            if (!_isFinishDialogShown) {
              _isFinishDialogShown = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showFinishDialog(viewModel);
              });
            }
            return const Scaffold(body: SizedBox());
          }

          final currentVocab = viewModel.currentVocab!;

          return Scaffold(
            extendBodyBehindAppBar: true,
            resizeToAvoidBottomInset: true,
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
                  // Decorative Circles
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
                    child: Column(
                      children: [
                        _buildHeader(context, viewModel),
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
                                      _buildQuestionCard(viewModel),
                                      const SizedBox(height: 32),
                                      _buildInputField(viewModel),
                                      if (currentVocab
                                              .userDefinedMeaning
                                              ?.isNotEmpty ==
                                          true)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              'Gợi ý: "${currentVocab.userDefinedMeaning}"',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Extra padding for scrolling above keyboard
                                      const SizedBox(height: 250),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottomSheet: _buildFooter(viewModel),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SentenceViewModel viewModel) {
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

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Câu ${viewModel.currentIndex + 1}/${viewModel.session!.vocabularies.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primaryPink,
                  ),
                ),
              ),

              const SizedBox(width: 48), // Balance spacing
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value:
                  (viewModel.currentIndex + 1) /
                  viewModel.session!.vocabularies.length,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(SentenceViewModel viewModel) {
    final vocab = viewModel.currentVocab!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
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
              'Tạo câu với từ',
              style: TextStyle(
                color: primaryPink.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
          Text(
            vocab.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: primaryPink,
              height: 1.2,
            ),
          ),
          if (vocab.phoneticText != null) ...[
            const SizedBox(height: 8),
            Text(
              vocab.phoneticText!,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 16),
          if (viewModel.partOfSpeech.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                viewModel.partOfSpeech,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(SentenceViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: !viewModel.isSubmitted,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
        ),
        decoration: InputDecoration(
          hintText: 'Nhập câu của bạn...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 24,
            horizontal: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: primaryPink, width: 2),
          ),
        ),
        textCapitalization: TextCapitalization.sentences,
        maxLines: 3,
        minLines: 1,
        onSubmitted: (_) {
          if (!viewModel.isSubmitted &&
              viewModel.feedbackState != FeedbackState.loading) {
            viewModel.checkAnswer(_textController.text);
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _nextButtonFocusNode.requestFocus(),
            );
          } else if (viewModel.isSubmitted) {
            _handleNext(viewModel);
          }
        },
      ),
    );
  }

  Widget _buildFooter(SentenceViewModel viewModel) {
    bool showFeedback =
        viewModel.isSubmitted &&
        viewModel.feedbackState != FeedbackState.initial;

    // Determine colors/icons based on state
    Color feedbackColor = primaryPink;
    if (viewModel.feedbackState == FeedbackState.correct)
      feedbackColor = correctColor;
    if (viewModel.feedbackState == FeedbackState.incorrect)
      feedbackColor = wrongColor;

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
          if (showFeedback) _buildFeedbackContent(viewModel, feedbackColor),

          if (showFeedback) const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              focusNode: _nextButtonFocusNode,
              onPressed:
                  viewModel.feedbackState == FeedbackState.loading
                      ? null
                      : () {
                        if (viewModel.isSubmitted) {
                          _handleNext(viewModel);
                        } else {
                          viewModel.checkAnswer(_textController.text);
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _nextButtonFocusNode.requestFocus(),
                          );
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    viewModel.isSubmitted ? feedbackColor : primaryPink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child:
                  viewModel.feedbackState == FeedbackState.loading
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text(
                        viewModel.isSubmitted ? 'Tiếp theo' : 'Kiểm tra',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackContent(SentenceViewModel viewModel, Color color) {
    final isCorrect = viewModel.feedbackState == FeedbackState.correct;
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.info_rounded;
    final title = isCorrect ? 'Tuyệt vời! 🎉' : 'Gợi ý AI 💡';

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCorrect
                        ? 'Câu của bạn rất tự nhiên!'
                        : 'Hãy tham khảo câu mẫu bên dưới nhé.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Feedback:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                viewModel.feedbackMessage,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        if (!isCorrect) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap:
                () => setState(
                  () => _showUserAnswerInFeedback = !_showUserAnswerInFeedback,
                ),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Xem câu của bạn',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _showUserAnswerInFeedback
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_showUserAnswerInFeedback)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _textController.text,
                style: const TextStyle(color: Color(0xFF555555), fontSize: 16),
              ),
            ),
        ],
      ],
    );
  }

  void _handleNext(SentenceViewModel viewModel) {
    viewModel.nextSentence();
    _textController.clear();
    _showUserAnswerInFeedback = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _showFinishDialog(SentenceViewModel viewModel) {
    viewModel.submitGameResult();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Column(
              children: [
                Icon(Icons.emoji_events_rounded, color: primaryPink, size: 48),
                SizedBox(height: 16),
                Text(
                  'Hoàn thành!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Đúng',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${viewModel.correctCount}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      Column(
                        children: [
                          const Text(
                            'Cần sửa',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${viewModel.wrongCount}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Đóng',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _initGame();
                        setState(() {
                          _textController.clear();
                          _showUserAnswerInFeedback = false;
                        });
                      },
                      child: const Text(
                        'Chơi lại',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              if (viewModel.wrongCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await viewModel.retryGame();
                        setState(() {
                          _textController.clear();
                          _showUserAnswerInFeedback = false;
                          _isFinishDialogShown = false;
                        });
                      },
                      child: const Text('Ôn tập câu cần sửa'),
                    ),
                  ),
                ),
            ],
          ),
    );
  }
}
