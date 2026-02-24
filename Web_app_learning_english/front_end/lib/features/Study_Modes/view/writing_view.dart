import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api/tts_service.dart';
import '../view_model/writing_view_model.dart';
import '../../Vocabulary/model/vocabulary.dart';
import '../../../core/widgets/game_finish_dialog.dart';
import '../../../core/widgets/custom_loading_widget.dart';

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

  static const Color correctColor = Colors.green;
  static const Color wrongColor = Colors.red;
  static const Color primaryPink = Color(0xFFE91E63);

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
        _textController.clear();
        _focusNode.requestFocus();
      },
      wrongWordsCount: _viewModel.wrongVocabularies.length,
      onRetryWrongWords:
          _viewModel.wrongVocabularies.isNotEmpty
              ? () {
                Navigator.of(context).pop(); // close dialog
                _viewModel.startWrongWordsRetry();
                _textController.clear();
                _focusNode.requestFocus();
              }
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.isBusy) {
          return Scaffold(
            body: CustomLoadingWidget(
              message: 'Đang tải dữ liệu...',
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        if (_viewModel.vocabularies.isEmpty) {
          return const Scaffold(body: Center(child: Text('Không có từ vựng.')));
        }

        final vocab = _viewModel.currentVocabulary!;

        return Scaffold(
          extendBodyBehindAppBar: true,
          resizeToAvoidBottomInset: true,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    Theme.of(context).brightness == Brightness.dark
                        ? [const Color(0xFF1E1E1E), const Color(0xFF3D1525)]
                        : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
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
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).primaryColor.withOpacity(0.3)
                              : Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
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
                  ),
                ),
              ],
            ),
          ),
          bottomSheet:
              _viewModel.isSubmitted
                  ? _buildFooter(_viewModel.currentVocabulary!)
                  : null,
        );
      },
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
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.1)
                            : Theme.of(context).cardColor.withOpacity(0.5),
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
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.1)
                          : Theme.of(context).cardColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Câu ${_viewModel.currentIndex + 1}/${_viewModel.vocabularies.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    color: primaryPink,
                  ),
                ),
              ),

              const SizedBox(width: 48), // Balance for back button
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value:
                  (_viewModel.currentIndex + 1) /
                  _viewModel.vocabularies.length,
              minHeight: 12,
              backgroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white.withOpacity(0.5),
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        border:
            Theme.of(context).brightness == Brightness.dark
                ? Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  width: 1,
                )
                : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.12),
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
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.translate_rounded, size: 16, color: primaryPink),
                const SizedBox(width: 8),
                Text(
                  'Dịch sang Tiếng Anh',
                  style: TextStyle(
                    color: primaryPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Text(
            vocab.userDefinedMeaning ?? '(Chưa có nghĩa)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  const Color(0xFF333333),
              height: 1.3,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (vocab.meanings?.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          Theme.of(context).brightness == Brightness.dark
                              ? [
                                Colors.blue.shade900.withOpacity(0.5),
                                Colors.blue.shade800.withOpacity(0.5),
                              ]
                              : [Colors.blue.shade50, Colors.blue.shade100],
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
                    vocab.meanings!.first.partOfSpeech ?? 'Word',
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue.shade200
                              : Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              const SizedBox(width: 16),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _ttsService.speak(vocab.word),
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.1)
                              : Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.2)
                                : Theme.of(context).dividerColor,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).shadowColor.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: primaryPink,
                      size: 24,
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
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryPink.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: !_viewModel.isSubmitted,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color:
              Theme.of(context).textTheme.bodyLarge?.color ??
              const Color(0xFF333333),
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: 'Nhập từ tiếng Anh...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 60, 24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).dividerColor
                      : Colors.white,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: primaryPink, width: 2),
          ),
          suffixIcon:
              _viewModel.isSubmitted
                  ? Icon(
                    _viewModel.feedbackState == FeedbackState.correct
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color:
                        _viewModel.feedbackState == FeedbackState.correct
                            ? correctColor
                            : wrongColor,
                    size: 28,
                  )
                  : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (_textController.text.trim().isNotEmpty) {
                            _checkAnswer();
                            FocusScope.of(context).unfocus();
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFFFF4081)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
        ),
        onSubmitted: (_) {
          if (!_viewModel.isSubmitted) {
            _checkAnswer();
          } else {
            _nextWord();
          }
        },
      ),
    );
  }

  Widget _buildFooter(Vocabulary vocab) {
    if (!_viewModel.isSubmitted) return const SizedBox.shrink();

    bool showFeedback = _viewModel.isSubmitted;
    Color color =
        _viewModel.feedbackState == FeedbackState.correct
            ? correctColor
            : wrongColor;
    String title =
        _viewModel.feedbackState == FeedbackState.correct
            ? 'Chính xác! 🎉'
            : 'Tiếc quá! 😅';
    String subtitle =
        _viewModel.feedbackState == FeedbackState.correct
            ? 'Bạn giỏi lắm!'
            : 'Đáp án đúng là:';
    IconData icon =
        _viewModel.feedbackState == FeedbackState.correct
            ? Icons.check_circle_rounded
            : Icons.info_outline_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFeedback)
            Column(
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
                            subtitle,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_viewModel.feedbackState != FeedbackState.correct) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: wrongColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: wrongColor.withOpacity(0.1)),
                    ),
                    child: Text(
                      vocab.word,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: wrongColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              focusNode: _nextButtonFocusNode,
              onPressed: _nextWord,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: color.withOpacity(0.4),
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
}
