import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/speaking_view_model.dart';
import '../../../api/stt_service.dart';

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
      viewModel.init().then((_) {
        viewModel.startGame(widget.userId, widget.folderId);
      });
    });
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
          backgroundColor: backgroundPink,
          body: SafeArea(
            child:
                viewModel.isLoading
                    ? _buildLoadingView()
                    : viewModel.isFinished
                    ? _buildResultView(viewModel)
                    : _buildGameView(viewModel),
          ),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryPink.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đang chuẩn bị...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
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
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: primaryPink),
            ),
          ),

          // Title
          // Title
          const Expanded(
            child: Text(
              'Luyện Nói',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ),

          // Score Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryPink,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        Container(
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF80AB), primaryPink],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(SpeakingViewModel viewModel, dynamic vocab) {
    Color borderColor = Colors.transparent;
    IconData? statusIcon;
    Color? iconColor;

    switch (viewModel.feedbackState) {
      case SpeakingFeedbackState.correct:
        borderColor = successGreen;
        statusIcon = Icons.check_circle;
        iconColor = successGreen;
        break;
      case SpeakingFeedbackState.incorrect:
        borderColor = errorRed;
        statusIcon = Icons.cancel;
        iconColor = errorRed;
        break;
      case SpeakingFeedbackState.skipped:
        borderColor = warningOrange;
        statusIcon = Icons.skip_next;
        iconColor = warningOrange;
        break;
      default:
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor != Colors.transparent ? borderColor : Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color:
                borderColor != Colors.transparent
                    ? borderColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status icon (Correct/Incorrect)
          if (statusIcon != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor!.withOpacity(0.1),
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
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (vocab.phoneticText != null &&
                    vocab.phoneticText!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        vocab.phoneticText!,
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.normal,
                          color: Colors.grey[700],
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
                          primaryPink.withOpacity(0.1),
                          Colors.purple.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      color: primaryPink,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nghe và Nhắc lại',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    color: primaryPink.withOpacity(0.2),
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
              child: Text(
                vocab.userDefinedMeaning!,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
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
                  foregroundColor: primaryPink,
                  backgroundColor: primaryPink.withOpacity(0.05),
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

  Widget _buildMicrophoneButton(SpeakingViewModel viewModel) {
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
                _buildWaveCircle(1.0, 0.0),
                _buildWaveCircle(0.8, 0.3),
                _buildWaveCircle(0.6, 0.6),
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
                                isListening ? errorRed : primaryPink,
                                isListening
                                    ? errorRed.withOpacity(0.8)
                                    : const Color(0xFFC2185B),
                              ]
                              : [Colors.grey[400]!, Colors.grey[500]!],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isListening ? errorRed : primaryPink)
                            .withOpacity(0.4),
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

  Widget _buildWaveCircle(double scale, double delay) {
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
              color: primaryPink.withOpacity((1 - animValue) * 0.5),
              width: 2,
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecognizedText(SpeakingViewModel viewModel) {
    if (viewModel.recognizedText.isEmpty &&
        viewModel.sttStatus != SttStatus.listening) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Nhấn micro để bắt đầu nói',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity:
          viewModel.recognizedText.isEmpty &&
                  viewModel.sttStatus != SttStatus.listening
              ? 0.0
              : 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: primaryPink.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            if (viewModel.sttStatus == SttStatus.listening &&
                viewModel.recognizedText.isEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryPink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang nghe...',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Text(
                    'Bạn nói:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${viewModel.recognizedText}"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
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
    final showNextButton =
        viewModel.feedbackState == SpeakingFeedbackState.correct ||
        viewModel.feedbackState == SpeakingFeedbackState.incorrect ||
        viewModel.feedbackState == SpeakingFeedbackState.skipped;

    if (showNextButton) {
      return ElevatedButton.icon(
        onPressed: viewModel.nextWord,
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Tiếp theo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Hint button
        OutlinedButton.icon(
          onPressed: viewModel.isWordRevealed ? null : viewModel.showHint,
          icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
          label: const Text('Gợi ý'),
          style: OutlinedButton.styleFrom(
            foregroundColor: warningOrange,
            side: BorderSide(
              color: viewModel.isWordRevealed ? Colors.grey : warningOrange,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Skip button
        OutlinedButton.icon(
          onPressed: viewModel.skipWord,
          icon: const Icon(Icons.skip_next_rounded, size: 20),
          label: const Text('Bỏ qua'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[600],
            side: BorderSide(color: Colors.grey[400]!),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultView(SpeakingViewModel viewModel) {
    final total = viewModel.totalWords;
    final correct = viewModel.correctCount;
    final percentage = total > 0 ? (correct / total * 100).toInt() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Trophy or result icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    percentage >= 70
                        ? [successGreen, successGreen.withOpacity(0.8)]
                        : percentage >= 50
                        ? [warningOrange, warningOrange.withOpacity(0.8)]
                        : [errorRed, errorRed.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (percentage >= 70 ? successGreen : primaryPink)
                      .withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              percentage >= 70
                  ? Icons.emoji_events_rounded
                  : percentage >= 50
                  ? Icons.thumb_up_rounded
                  : Icons.refresh_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            percentage >= 70
                ? 'Xuất sắc!'
                : percentage >= 50
                ? 'Khá tốt!'
                : 'Cần luyện thêm!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Bạn đã hoàn thành bài luyện nói',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),

          const SizedBox(height: 32),

          // Stats card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Percentage circle
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: percentage / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 70
                              ? successGreen
                              : percentage >= 50
                              ? warningOrange
                              : errorRed,
                        ),
                      ),
                    ),
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stats row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      Icons.check_circle,
                      successGreen,
                      '${viewModel.correctCount}',
                      'Đúng',
                    ),
                    _buildStatItem(
                      Icons.cancel,
                      errorRed,
                      '${viewModel.wrongCount}',
                      'Sai',
                    ),
                    _buildStatItem(
                      Icons.skip_next,
                      warningOrange,
                      '${viewModel.skippedCount}',
                      'Bỏ qua',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Action buttons
          if (viewModel.wrongVocabularies.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: viewModel.startWrongWordsRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Ôn lại ${viewModel.wrongVocabularies.length} từ sai',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: warningOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  () => viewModel.retryGame(widget.userId, widget.folderId),
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Chơi lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Về trang chính'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryPink,
                side: const BorderSide(color: primaryPink),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }
}
