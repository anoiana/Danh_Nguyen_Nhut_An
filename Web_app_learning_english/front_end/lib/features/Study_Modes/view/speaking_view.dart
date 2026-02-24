import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/speaking_view_model.dart';
import '../../../api/stt_service.dart';
import '../../../core/widgets/custom_loading_widget.dart';
import '../../../core/widgets/game_finish_dialog.dart';

// Theme Colors
const Color primaryPink = Color(0xFFE91E63);
const Color backgroundPink = Color(0xFFFCE4EC);
const Color successGreen = Color(0xFF4CAF50);
const Color errorRed = Color(0xFFE53935);
const Color warningOrange = Color(0xFFFF9800);

class SpeakingView extends StatefulWidget {
  final int folderId;
  final String folderName;
  final int userId;

  const SpeakingView({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.userId,
  });

  @override
  State<SpeakingView> createState() => _SpeakingViewState();
}

class _SpeakingViewState extends State<SpeakingView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  bool _hasShownFinishDialog = false;

  @override
  void initState() {
    super.initState();

    // Pulse animation for microphone button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation for listening state
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Initialize ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<SpeakingViewModel>();
      viewModel.addListener(() => _onViewModelChanged(viewModel));
      viewModel.init().then((_) {
        viewModel.startGame(widget.userId, widget.folderId);
      });
    });
  }

  void _onViewModelChanged(SpeakingViewModel viewModel) {
    // Auto-show GameFinishDialog when result submission is complete
    if (viewModel.isFinished &&
        !viewModel.isSubmittingResult &&
        !_hasShownFinishDialog &&
        mounted) {
      _hasShownFinishDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showFinishDialog(viewModel);
      });
    }
  }

  void _showFinishDialog(SpeakingViewModel viewModel) {
    showGameFinishDialog(
      context: context,
      correctCount: viewModel.correctCount,
      wrongCount: viewModel.wrongCount + viewModel.skippedCount,
      extraStats:
          viewModel.skippedCount > 0
              ? {'Bỏ qua': '${viewModel.skippedCount}'}
              : null,
      onClose: () {
        Navigator.of(context).pop(); // close dialog
        Navigator.of(context).pop(); // back to selection
      },
      onReplay: () {
        Navigator.of(context).pop(); // close dialog
        _hasShownFinishDialog = false;
        viewModel.retryGame(widget.userId, widget.folderId);
      },
      wrongWordsCount: viewModel.wrongVocabularies.length,
      onRetryWrongWords:
          viewModel.wrongVocabularies.isNotEmpty
              ? () {
                Navigator.of(context).pop(); // close dialog
                _hasShownFinishDialog = false;
                viewModel.startWrongWordsRetry();
              }
              : null,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SpeakingViewModel>(
      builder: (context, viewModel, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // Control pulse animation based on state
        if (viewModel.sttStatus == SttStatus.listening) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors:
                    isDark
                        ? [
                          const Color(0xFF1E1E1E),
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                        ]
                        : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
              ),
            ),
            child: SafeArea(
              child:
                  viewModel.isLoading
                      ? _buildLoadingView()
                      : (viewModel.isSubmittingResult || viewModel.isFinished)
                      ? _buildSubmittingView()
                      : _buildGameView(viewModel),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return CustomLoadingWidget(
      message: 'Đang tải dữ liệu...',
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildSubmittingView() {
    return CustomLoadingWidget(
      message: 'Đang lưu kết quả...',
      color: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildGameView(SpeakingViewModel viewModel) {
    final vocab = viewModel.currentVocabulary;
    if (vocab == null) return const SizedBox();

    return Column(
      children: [
        // Header
        _buildHeader(viewModel),

        // Progress bar
        _buildProgressBar(viewModel),

        // Main content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  // Word card
                  _buildWordCard(viewModel, vocab),

                  const SizedBox(height: 32),

                  // Status hint text
                  _buildStatusHint(viewModel),

                  const SizedBox(height: 24),

                  // Microphone button
                  _buildMicrophoneButton(viewModel),

                  const SizedBox(height: 24),

                  // Recognized text
                  _buildRecognizedText(viewModel),

                  const SizedBox(height: 24),

                  // Action buttons
                  _buildActionButtons(viewModel),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(SpeakingViewModel viewModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.1)
                        : Theme.of(context).cardColor.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          // Title

          // Score Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withOpacity(0.1)
                      : Theme.of(context).cardColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: successGreen, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${viewModel.correctCount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: successGreen,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.cancel, color: errorRed, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${viewModel.wrongCount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: errorRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(SpeakingViewModel viewModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress =
        viewModel.totalWords > 0
            ? (viewModel.currentIndex + 1) / viewModel.totalWords
            : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Từ ${viewModel.currentIndex + 1}/${viewModel.totalWords}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(SpeakingViewModel viewModel, dynamic vocab) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color borderColor = Colors.transparent;
    IconData? statusIcon;
    Color? iconColor;

    switch (viewModel.feedbackState) {
      case SpeakingFeedbackState.correct:
        borderColor = successGreen;
        statusIcon = Icons.check_circle_rounded;
        iconColor = successGreen;
        break;
      case SpeakingFeedbackState.incorrect:
        borderColor = errorRed;
        statusIcon = Icons.cancel_rounded;
        iconColor = errorRed;
        break;
      case SpeakingFeedbackState.skipped:
        borderColor = warningOrange;
        statusIcon = Icons.skip_next_rounded;
        iconColor = warningOrange;
        break;
      default:
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              borderColor != Colors.transparent
                  ? borderColor
                  : isDark
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Colors.transparent,
          width: borderColor != Colors.transparent ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color:
                borderColor != Colors.transparent
                    ? borderColor.withOpacity(0.25)
                    : isDark
                    ? Colors.black.withOpacity(0.3)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status icon (Correct/Incorrect/Skipped)
          if (statusIcon != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor!.withOpacity(isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: iconColor, size: 40),
              ),
            ),

          // WORD DISPLAY AREA
          if (viewModel.isWordRevealed ||
              viewModel.feedbackState == SpeakingFeedbackState.incorrect ||
              viewModel.feedbackState == SpeakingFeedbackState.skipped ||
              viewModel.feedbackState == SpeakingFeedbackState.correct)
            // REVEALED STATE
            Column(
              children: [
                Text(
                  vocab.word,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color:
                        isDark
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color ??
                                Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (vocab.phoneticText != null &&
                    vocab.phoneticText!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1)
                                : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        vocab.phoneticText!,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color:
                              isDark
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.8)
                                  : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            // HIDDEN STATE (PREMIUM UI)
            Column(
              children: [
                GestureDetector(
                  onTap: viewModel.replayWord,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                          Colors.purple.withOpacity(isDark ? 0.1 : 0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border:
                          isDark
                              ? Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                                width: 1.5,
                              )
                              : null,
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nghe và Nhắc lại',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),

          // Meaning
          if (vocab.userDefinedMeaning != null &&
              (viewModel.isWordRevealed ||
                  viewModel.feedbackState != SpeakingFeedbackState.initial))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.08)
                          : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  vocab.userDefinedMeaning!,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Replay button
          if (viewModel.isWordRevealed ||
              viewModel.feedbackState != SpeakingFeedbackState.initial)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton.icon(
                onPressed: viewModel.replayWord,
                icon: const Icon(Icons.volume_up_rounded, size: 18),
                label: const Text('Nghe lại'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(isDark ? 0.15 : 0.05),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusHint(SpeakingViewModel viewModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isListening = viewModel.sttStatus == SttStatus.listening;

    if (viewModel.feedbackState != SpeakingFeedbackState.initial &&
        viewModel.feedbackState != SpeakingFeedbackState.listening) {
      return const SizedBox.shrink();
    }

    String hintText;
    IconData hintIcon;
    Color hintColor;

    if (isListening) {
      hintText = 'Đang lắng nghe bạn...';
      hintIcon = Icons.hearing_rounded;
      hintColor = errorRed;
    } else {
      hintText = 'Nhấn micro để bắt đầu nói';
      hintIcon = Icons.mic_none_rounded;
      hintColor = isDark ? Theme.of(context).colorScheme.primary : primaryPink;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(isListening),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: hintColor.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: hintColor.withOpacity(isDark ? 0.3 : 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(hintIcon, size: 18, color: hintColor),
            const SizedBox(width: 8),
            Text(
              hintText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMicrophoneButton(SpeakingViewModel viewModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isListening = viewModel.sttStatus == SttStatus.listening;
    final canListen =
        viewModel.feedbackState == SpeakingFeedbackState.initial ||
        viewModel.feedbackState == SpeakingFeedbackState.listening;

    return GestureDetector(
      onTap: canListen ? viewModel.startListening : null,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Wave circles when listening
              if (isListening) ...[
                _buildWaveCircle(1.0, 0.0, isDark),
                _buildWaveCircle(0.8, 0.3, isDark),
                _buildWaveCircle(0.6, 0.6, isDark),
              ],

              // Main button
              Transform.scale(
                scale: isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors:
                          canListen
                              ? [
                                isListening
                                    ? errorRed
                                    : Theme.of(context).colorScheme.primary,
                                isListening
                                    ? errorRed.withOpacity(0.8)
                                    : const Color(0xFFC2185B),
                              ]
                              : [
                                isDark ? Colors.grey[700]! : Colors.grey[400]!,
                                isDark ? Colors.grey[800]! : Colors.grey[500]!,
                              ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isListening
                                ? errorRed
                                : Theme.of(context).colorScheme.primary)
                            .withOpacity(canListen ? 0.4 : 0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWaveCircle(double scale, double delay, bool isDark) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final animValue = ((_waveController.value + delay) % 1.0);
        return Container(
          width: 100 + (80 * animValue * scale),
          height: 100 + (80 * animValue * scale),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withOpacity((1 - animValue) * 0.5),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecognizedText(SpeakingViewModel viewModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (viewModel.recognizedText.isEmpty &&
        viewModel.sttStatus != SttStatus.listening) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity:
          viewModel.recognizedText.isEmpty &&
                  viewModel.sttStatus != SttStatus.listening
              ? 0.0
              : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(6),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(isDark ? 0.3 : 0.1),
          ),
        ),
        child: Column(
          children: [
            if (viewModel.sttStatus == SttStatus.listening &&
                viewModel.recognizedText.isEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Đang nhận dạng giọng nói...',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.record_voice_over_rounded,
                        size: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Bạn nói:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${viewModel.recognizedText}"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color ??
                                  Colors.black87,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(SpeakingViewModel viewModel) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showNextButton =
        viewModel.feedbackState == SpeakingFeedbackState.correct ||
        viewModel.feedbackState == SpeakingFeedbackState.incorrect ||
        viewModel.feedbackState == SpeakingFeedbackState.skipped;

    if (showNextButton) {
      final isCorrect =
          viewModel.feedbackState == SpeakingFeedbackState.correct;
      final buttonColor = isCorrect ? successGreen : primaryPink;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: viewModel.nextWord,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            elevation: 4,
            shadowColor: buttonColor.withOpacity(0.4),
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
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hint button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: viewModel.isWordRevealed ? null : viewModel.showHint,
            icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
            label: const Text('Gợi ý'),
            style: OutlinedButton.styleFrom(
              foregroundColor: warningOrange,
              side: BorderSide(
                color:
                    viewModel.isWordRevealed
                        ? (isDark ? Colors.grey[700]! : Colors.grey[300]!)
                        : warningOrange,
                width: 1.5,
              ),
              disabledForegroundColor:
                  isDark ? Colors.grey[600] : Colors.grey[400],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Skip button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: viewModel.skipWord,
            icon: const Icon(Icons.skip_next_rounded, size: 20),
            label: const Text('Bỏ qua'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.grey[400] : Colors.grey[600],
              side: BorderSide(
                color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
