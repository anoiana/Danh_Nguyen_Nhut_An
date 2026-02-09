import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../api/auth_service.dart';
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
      child: Stack(
        children: [
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
          Column(
            children: [
              _buildSimpleHeader(
                title: 'Nghe & Viết',
                subtitle:
                    '${viewModel.currentVocabIndex + 1}/${session.vocabularies.length}',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPink.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primaryPink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Điền từ vào ô trống',
                                style: TextStyle(
                                  color: primaryPink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onTap: viewModel.speakCurrentVocab,
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.pink.shade50,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.pink.shade100,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.volume_up_rounded,
                                  size: 60,
                                  color: primaryPink,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Chạm để nghe lại',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (viewModel.isSubmitted &&
                          viewModel.feedbackState ==
                              FeedbackState.incorrect) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Gợi ý ý nghĩa:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currentVocab.userDefinedMeaning ?? 'Không có',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade800),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPink.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _vocabController,
                          autofocus: true,
                          textInputAction: TextInputAction.send,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          onSubmitted: (val) {
                            if (viewModel.isSubmitted) {
                              _vocabController.clear();
                              viewModel.nextVocabWord();
                            } else {
                              viewModel.checkVocabAnswer(val);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Nhập từ bạn nghe được...',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(
                                color: primaryPink,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!viewModel.isSubmitted)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed:
                                () => viewModel.checkVocabAnswer(
                                  _vocabController.text,
                                ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPink,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: primaryPink.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Kiểm tra',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 120), // Bottom Sheet space
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader({required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: primaryPink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 48), // Balance
        ],
      ),
    );
  }

  Widget _buildVocabFooter(ListeningViewModel viewModel) {
    if (!viewModel.isSubmitted) return const SizedBox.shrink();
    final isCorrect = viewModel.feedbackState == FeedbackState.correct;
    final session = viewModel.vocabSession;
    if (session == null) return const SizedBox.shrink();
    final currentVocab = session.vocabularies[viewModel.currentVocabIndex];

    final color = isCorrect ? correctColor : wrongColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
                color: color,
                size: 40,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCorrect ? 'Chính xác! 🎉' : 'Chưa đúng',
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        text: 'Đáp án đúng: ',
                        style: TextStyle(color: Colors.grey[600]),
                        children: [
                          TextSpan(
                            text: currentVocab.word,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                _vocabController.clear();
                if (viewModel.currentVocabIndex >=
                    session.vocabularies.length - 1) {
                  viewModel.nextVocabWord();
                  _showFinishDialog(viewModel);
                } else {
                  viewModel.nextVocabWord();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Tiếp theo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(ListeningViewModel viewModel) {
    viewModel.submitVocabResult(); // Auto submit?

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
            content: Container(
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
                        'Sai',
                        style: TextStyle(
                          color: Colors.red,
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
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      child: const Text(
                        'Đóng',
                        style: TextStyle(color: Colors.grey),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
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
                      onPressed: () {
                        Navigator.pop(ctx);
                        viewModel.retryVocabGame(
                          widget.userId!,
                          widget.folderId!,
                        );
                      },
                      child: const Text('Luyện lại'),
                    ),
                  ),
                ],
              ),
              if (viewModel.wrongVocabularies.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
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
                      child: const Text('Ôn tập từ sai'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        viewModel.startWrongWordsRetry();
                      },
                    ),
                  ),
                ),
            ],
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
            future: AuthService.translateWord(text),
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
