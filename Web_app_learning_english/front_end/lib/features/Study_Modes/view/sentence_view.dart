import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../view_model/sentence_view_model.dart';
import '../../../core/widgets/custom_loading_widget.dart';

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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _inputFieldKey = GlobalKey();
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
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Wait for keyboard to animate up
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _inputFieldKey.currentContext != null) {
          Scrollable.ensureVisible(
            _inputFieldKey.currentContext!,
            alignment: 0.5, // Center the input field in the view
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
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
    _focusNode.removeListener(_onFocusChange);
    _viewModel.dispose();
    _textController.dispose();
    _focusNode.dispose();
    _nextButtonFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<SentenceViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isBusy) {
            return const Scaffold(
              body: CustomLoadingWidget(
                message: 'Đang tải dữ liệu...',
                color: primaryPink,
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
                                controller: _scrollController,
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryPink.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.create_rounded, size: 16, color: primaryPink),
                const SizedBox(width: 8),
                Text(
                  'Tạo câu với từ',
                  style: TextStyle(
                    color: primaryPink.withOpacity(0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            vocab.word,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Color(0xFF333333),
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          if (vocab.phoneticText != null) ...[
            const SizedBox(height: 12),
            Text(
              vocab.phoneticText!,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
                fontStyle: FontStyle.normal,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (viewModel.partOfSpeech.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                viewModel.partOfSpeech,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(SentenceViewModel viewModel) {
    return Container(
      key: _inputFieldKey,
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
        // textAlign: TextAlign.center, // Removed center alignment for better input flow with suffix
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
            vertical: 20,
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
          suffixIcon:
              viewModel.isSubmitted
                  ? null
                  : Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: IconButton(
                      onPressed: () {
                        if (viewModel.feedbackState != FeedbackState.loading) {
                          viewModel.checkAnswer(_textController.text);
                          FocusScope.of(context).unfocus(); // Close keyboard
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _nextButtonFocusNode.requestFocus(),
                          );
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: primaryPink,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon:
                          viewModel.feedbackState == FeedbackState.loading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(
                                Icons.arrow_upward_rounded,
                                size: 24,
                              ),
                    ),
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
    if (!viewModel.isSubmitted) return const SizedBox.shrink();

    bool showFeedback =
        viewModel.isSubmitted &&
        viewModel.feedbackState != FeedbackState.initial;

    Color feedbackColor = primaryPink;
    if (viewModel.feedbackState == FeedbackState.correct) {
      feedbackColor = correctColor;
    }
    if (viewModel.feedbackState == FeedbackState.incorrect) {
      feedbackColor = wrongColor;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFeedback) _buildFeedbackContent(viewModel, feedbackColor),
          if (showFeedback) const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              focusNode: _nextButtonFocusNode,
              onPressed: () => _handleNext(viewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: feedbackColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: feedbackColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tiếp theo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackContent(SentenceViewModel viewModel, Color color) {
    final isCorrect = viewModel.feedbackState == FeedbackState.correct;
    final icon =
        isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded;
    final title = isCorrect ? 'Tuyệt vời!' : 'Gợi ý AI';

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
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
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCorrect
                        ? 'Câu của bạn rất tự nhiên và chính xác.'
                        : 'Hãy tham khảo cách diễn đạt dưới đây.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Feedback',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                viewModel.feedbackMessage,
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (!isCorrect) ...[
          const SizedBox(height: 16),
          InkWell(
            onTap:
                () => setState(
                  () => _showUserAnswerInFeedback = !_showUserAnswerInFeedback,
                ),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem lại câu của bạn',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showUserAnswerInFeedback
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_showUserAnswerInFeedback)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _textController.text,
                style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 16,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                ),
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
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Main Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Hoàn thành!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Chúc mừng bạn đã hoàn thành bài tập.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 32),

                      // Stats Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: primaryPink.withOpacity(0.1),
                          ),
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
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${viewModel.correctCount}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: primaryPink.withOpacity(0.2),
                            ),
                            Column(
                              children: [
                                Text(
                                  'Cần sửa',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${viewModel.wrongCount}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                foregroundColor: Colors.grey[700],
                              ),
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Đóng',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryPink,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
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
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange[700],
                                backgroundColor: Colors.orange[50],
                                side: BorderSide(
                                  color: Colors.orange.withOpacity(0.5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              label: const Text(
                                'Ôn tập các câu cần sửa',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Floating Icon
                Positioned(
                  top: -50,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE91E63).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
