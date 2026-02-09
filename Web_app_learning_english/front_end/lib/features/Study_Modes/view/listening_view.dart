import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Dictionary/service/dictionary_service.dart';
import '../../../core/widgets/speech_rate_slider.dart';
import '../view_model/listening_view_model.dart';
import '../model/listening_content.dart';
import '../../Vocabulary/model/vocabulary.dart';
import '../model/game_session.dart';

class ListeningView extends StatefulWidget {
  final int? folderId;
  final int? userId;
  final int? level;
  final String? topic;
  final String? subType;
  final ListeningGameType initialType;

  const ListeningView({
    super.key,
    this.folderId,
    this.userId,
    this.level,
    this.topic,
    this.subType,
    required this.initialType,
  });

  @override
  State<ListeningView> createState() => _ListeningViewState();
}

class _ListeningViewState extends State<ListeningView>
    with SingleTickerProviderStateMixin {
  final ListeningViewModel _viewModel = ListeningViewModel();
  late TabController _tabController;
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color correctColor = Colors.green;
  static const Color wrongColor = Colors.red;

  final TextEditingController _vocabController = TextEditingController();
  final FocusNode _vocabFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel.init();
    if (widget.initialType == ListeningGameType.vocabulary) {
      _viewModel.startVocabListening(widget.userId!, widget.folderId!).then((
        _,
      ) {
        _viewModel.speakCurrentVocab();
      });
    } else {
      _viewModel.startAIListening(
        widget.folderId!,
        widget.level!,
        widget.topic!,
        widget.subType!,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vocabController.dispose();
    _vocabFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ListeningViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: primaryPink),
              ),
            );
          }

          Widget content;
          if (viewModel.gameType == ListeningGameType.vocabulary) {
            content = _buildVocabularyView(viewModel);
          } else if (viewModel.gameType == ListeningGameType.ai) {
            content = _buildAIView(viewModel);
          } else {
            content = const Center(child: Text("Error: No game type"));
          }

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
              child: content,
            ),
            bottomSheet:
                viewModel.gameType == ListeningGameType.vocabulary
                    ? _buildVocabFooter(viewModel)
                    : null,
          );
        },
      ),
    );
  }

  // --- Vocabulary Mode UI ---
  Widget _buildVocabularyView(ListeningViewModel viewModel) {
    final session = viewModel.vocabSession;
    if (session == null) return const Center(child: Text("Session not found"));
    final currentVocab = session.vocabularies[viewModel.currentVocabIndex];

    return SafeArea(
      child: Column(
        children: [
          _buildVocabHeader(viewModel),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  _buildListeningCard(viewModel, currentVocab),
                  const SizedBox(height: 32),
                  _buildVocabInputField(viewModel),
                  const SizedBox(height: 120), // Bottom Sheet space
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabHeader(ListeningViewModel viewModel) {
    final session = viewModel.vocabSession;
    if (session == null) return const SizedBox.shrink();

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
                'Câu ${viewModel.currentVocabIndex + 1}/${session.vocabularies.length}',
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
                  (viewModel.currentVocabIndex + 1) /
                  session.vocabularies.length,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningCard(
    ListeningViewModel viewModel,
    Vocabulary currentVocab,
  ) {
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
                const Icon(
                  Icons.headphones_rounded,
                  size: 16,
                  color: primaryPink,
                ),
                const SizedBox(width: 8),
                Text(
                  'Nghe và điền từ',
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

          GestureDetector(
            onTap: viewModel.speakCurrentVocab,
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF0F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryPink.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 10,
                    offset: const Offset(-5, -5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                size: 64,
                color: primaryPink,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Chạm để nghe lại',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (viewModel.isSubmitted &&
              viewModel.feedbackState == FeedbackState.incorrect) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Nghĩa: ${currentVocab.userDefinedMeaning ?? "Chưa có"}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVocabInputField(ListeningViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _vocabController,
        focusNode: _vocabFocusNode,
        autofocus: true,
        textInputAction: TextInputAction.send,
        enabled: !viewModel.isSubmitted,
        textAlign: TextAlign.start,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF333333),
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: 'Nhập từ bạn nghe được...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 60, 24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: primaryPink.withOpacity(0.3)),
          ),
          suffixIcon:
              viewModel.isSubmitted
                  ? Icon(
                    viewModel.feedbackState == FeedbackState.correct
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color:
                        viewModel.feedbackState == FeedbackState.correct
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
                          if (_vocabController.text.trim().isNotEmpty) {
                            viewModel.checkVocabAnswer(_vocabController.text);
                            // Don't unfocus to keep keyboard up for next if needed,
                            // or unfocus if preferred. WritingView unfocuses.
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
                                color: primaryPink.withOpacity(0.4),
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
        onSubmitted: (val) {
          if (!viewModel.isSubmitted) {
            if (val.trim().isNotEmpty) {
              viewModel.checkVocabAnswer(val);
            }
          } else {
            // Already submitted, maybe next?
            _handleNextVocab(viewModel);
          }
        },
      ),
    );
  }

  void _handleNextVocab(ListeningViewModel viewModel) {
    final session = viewModel.vocabSession;
    if (session == null) return;

    _vocabController.clear();
    // Ensure we request focus back after a short delay for the animation
    Future.delayed(Duration.zero, () => _vocabFocusNode.requestFocus());

    if (viewModel.currentVocabIndex >= session.vocabularies.length - 1) {
      _showFinishDialog(viewModel);
    } else {
      viewModel.nextVocabWord();
    }
  }

  Widget _buildVocabFooter(ListeningViewModel viewModel) {
    if (!viewModel.isSubmitted) return const SizedBox.shrink();

    final isCorrect = viewModel.feedbackState == FeedbackState.correct;
    final session = viewModel.vocabSession;
    if (session == null) return const SizedBox.shrink();
    final currentVocab = session.vocabularies[viewModel.currentVocabIndex];

    final color = isCorrect ? correctColor : wrongColor;
    final title = isCorrect ? 'Chính xác! 🎉' : 'Tiếc quá! 😅';
    final subtitle = isCorrect ? 'Bạn nghe rất tốt!' : 'Đáp án đúng là:';
    final icon =
        isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded;

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
              if (!isCorrect) ...[
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
                    currentVocab.word,
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
              onPressed: () => _handleNextVocab(viewModel),
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

  void _showFinishDialog(ListeningViewModel viewModel) {
    viewModel.submitVocabResult();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              clipBehavior: Clip.none,
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  // Main Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 40),
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
                          'Bạn đã hoàn thành bài luyện tập.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
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
                                    'Sai',
                                    style: TextStyle(
                                      color: Colors.red[700],
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
                                      color: Colors.red[700],
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
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  viewModel.retryVocabGame(
                                    widget.userId!,
                                    widget.folderId!,
                                  );
                                },
                                child: const Text(
                                  'Chơi lại',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (viewModel.wrongVocabularies.isNotEmpty)
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
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  viewModel.startWrongWordsRetry();
                                },
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Ôn tập từ sai',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Floating Icon
                  Container(
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
                ],
              ),
            ),
          ),
    );
  }

  // --- AI Mode UI ---
  Widget _buildAIView(ListeningViewModel viewModel) {
    final content = viewModel.aiContent;
    if (content == null) return const Center(child: Text("Content not found"));

    return SafeArea(
      child: Column(
        children: [
          // Custom Header for AI Mode
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: primaryPink),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    viewModel.aiSubType == 'mcq' ? 'Trắc nghiệm' : 'Điền từ',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.speed_rounded, color: primaryPink),
                  onPressed:
                      () => showSpeechRateBottomSheet(
                        context,
                        viewModel.ttsService,
                      ),
                ),
              ],
            ),
          ),

          // Custom Styled Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: primaryPink,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: primaryPink.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[700],
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: "Bài tập"), Tab(text: "Transcript")],
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAITaskContent(viewModel),
                  _buildTranscriptView(viewModel),
                ],
              ),
            ),
          ),

          _buildPlaybackControls(viewModel),
        ],
      ),
    );
  }

  Widget _buildAITaskContent(ListeningViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (viewModel.isSubmitted)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Kết quả của bạn',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${viewModel.aiSubType == 'mcq' ? viewModel.mcqScore : viewModel.fitbScore}",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

        if (viewModel.aiSubType == 'mcq')
          ...viewModel.aiContent!.mcq.asMap().entries.map(
            (e) => _buildMcqCard(viewModel, e.key, e.value),
          ),

        if (viewModel.aiSubType == 'fitb' && viewModel.aiContent!.fitb != null)
          _buildFitbCard(viewModel),

        const SizedBox(height: 32),

        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed:
                viewModel.isSubmitted
                    ? viewModel.resetAIGame
                    : viewModel.checkAIAnswers,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: primaryPink.withOpacity(0.4),
            ),
            child: Text(
              viewModel.isSubmitted ? "Làm lại bài" : "Nộp bài",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPlaybackControls(ListeningViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -10),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: primaryPink,
                inactiveTrackColor: Colors.grey[200],
                thumbColor: primaryPink,
                overlayColor: primaryPink.withOpacity(0.1),
              ),
              child: Slider(
                value: viewModel.playbackProgress,
                onChanged: (val) {}, // Seek not implemented yet, just visual
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded),
                onPressed:
                    viewModel
                        .replay, // Actually replay from start in VM currently, ideal would be -10s
                color: Colors.grey[700],
              ),
              const SizedBox(width: 24),
              GestureDetector(
                onTap: viewModel.togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryPink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryPink.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    viewModel.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: () => viewModel.ttsService.stop(),
                color: Colors.grey[700],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMcqCard(
    ListeningViewModel viewModel,
    int index,
    ListeningMCQ question,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryPink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryPink,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    question.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...question.options.map((option) {
              bool isSelected = viewModel.selectedMcqOptions[index] == option;
              bool isCorrect = option == question.answer;

              Color borderColor = Colors.grey.shade300;
              Color bgColor = Colors.transparent;
              Color iconColor = Colors.grey;
              IconData icon = Icons.circle_outlined;

              if (viewModel.isSubmitted) {
                if (isCorrect) {
                  borderColor = Colors.green;
                  bgColor = Colors.green.shade50;
                  iconColor = Colors.green;
                  icon = Icons.check_circle;
                } else if (isSelected) {
                  borderColor = Colors.red;
                  bgColor = Colors.red.shade50;
                  iconColor = Colors.red;
                  icon = Icons.cancel;
                }
              } else {
                if (isSelected) {
                  borderColor = primaryPink;
                  bgColor = Colors.pink.shade50;
                  iconColor = primaryPink;
                  icon = Icons.radio_button_checked;
                }
              }

              return GestureDetector(
                onTap:
                    viewModel.isSubmitted
                        ? null
                        : () => viewModel.onMcqOptionSelected(index, option),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFitbCard(ListeningViewModel viewModel) {
    if (viewModel.aiContent == null || viewModel.aiContent!.fitb == null)
      return const SizedBox.shrink();

    final textParts = viewModel.aiContent!.fitb!.textWithBlanks.split(
      RegExp(r'____\(\d+\)____'),
    );
    final spans = <InlineSpan>[];
    for (var i = 0; i < textParts.length; i++) {
      // Regular text
      spans.add(
        TextSpan(text: textParts[i], style: const TextStyle(height: 2)),
      );

      // Blank field
      if (i < viewModel.fitbControllers.length) {
        final isCorrect = viewModel.fitbResults[i];
        Color underlineColor = Colors.grey;
        if (viewModel.isSubmitted) {
          underlineColor = (isCorrect ?? false) ? Colors.green : Colors.red;
        }

        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: viewModel.fitbControllers[i],
                readOnly: viewModel.isSubmitted,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: underlineColor,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: underlineColor),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryPink, width: 2),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: RichText(
          text: TextSpan(
            children: spans,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 16,
              height: 1.8,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscriptView(ListeningViewModel viewModel) {
    if (viewModel.aiContent == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          "Bài nghe",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        SelectableText(
          viewModel.aiContent!.transcript,
          style: const TextStyle(
            fontSize: 16,
            height: 1.8,
            color: Color(0xFF444444),
          ),
          contextMenuBuilder: (context, state) {
            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: state.contextMenuAnchors,
              buttonItems: [
                ContextMenuButtonItem(
                  onPressed: () {
                    final text =
                        state.textEditingValue.selection
                            .textInside(state.textEditingValue.text)
                            .trim();
                    if (text.isNotEmpty) viewModel.speak(text);
                  },
                  label: 'Phát âm',
                ),
                ContextMenuButtonItem(
                  onPressed: () {
                    final text =
                        state.textEditingValue.selection
                            .textInside(state.textEditingValue.text)
                            .trim();
                    if (text.isNotEmpty) _showTranslation(text);
                  },
                  label: 'Dịch',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  void _showTranslation(String text) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TranslationBottomSheet(text: text),
    );
  }
}

class TranslationBottomSheet extends StatelessWidget {
  final String text;
  const TranslationBottomSheet({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<String>(
            future: DictionaryService.translateWord(text),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(
                  color: Color(0xFFE91E63),
                );
              }
              return Text(
                snapshot.data ?? 'Không thể dịch',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
