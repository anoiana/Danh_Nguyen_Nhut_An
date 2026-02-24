import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Dictionary/service/dictionary_service.dart';
import '../../../core/widgets/speech_rate_bottom_sheet.dart';
import '../view_model/listening_view_model.dart';
import '../model/listening_content.dart';
import '../model/game_session.dart';
import '../../../core/widgets/custom_loading_widget.dart';
import '../../../core/widgets/game_finish_dialog.dart';

import '../../../core/widgets/custom_error_widget.dart';
import 'widgets/vocabulary_card.dart';
import 'widgets/ai_task_content.dart';
import 'widgets/translation_bottom_sheet.dart';

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
    _loadData();
  }

  void _loadData() {
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
            return Scaffold(
              body: CustomLoadingWidget(
                message: 'Đang tải bài nghe...',
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          if (viewModel.errorMessage.isNotEmpty) {
            return Scaffold(
              body: CustomErrorWidget(
                errorMessage: viewModel.errorMessage,
                onRetry: _loadData,
                onClose: () => Navigator.pop(context),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      Theme.of(context).brightness == Brightness.dark
                          ? [
                            const Color(0xFF1E1E1E),
                            Theme.of(context).primaryColor.withOpacity(0.5),
                          ]
                          : [const Color(0xFFFCE4EC), const Color(0xFFF8BBD0)],
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
                  VocabularyCard(
                    viewModel: viewModel,
                    currentVocab: currentVocab,
                  ),
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
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.1)
                            : Theme.of(context).cardColor,
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
                  fontStyle: FontStyle.italic,
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
              backgroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Theme.of(context).cardColor.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabInputField(ListeningViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.transparent
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border:
            Theme.of(context).brightness == Brightness.dark
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
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
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color:
              Theme.of(context).textTheme.bodyLarge?.color ??
              const Color(0xFF333333),
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: 'Nhập từ bạn nghe được...',
          hintStyle: TextStyle(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[500]
                    : Colors.grey[400],
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

    if (viewModel.currentVocabIndex >= session.vocabularies.length - 1) {
      _showFinishDialog(viewModel);
    } else {
      viewModel.nextVocabWord();
      // Auto-focus sau khi widget rebuild xong (TextField được enable lại)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _vocabFocusNode.requestFocus();
        }
      });
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
        color: Theme.of(context).cardColor,
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
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? wrongColor.withOpacity(0.15)
                            : wrongColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: wrongColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    currentVocab.word,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade300
                              : wrongColor,
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

  void _showFinishDialog(ListeningViewModel viewModel) async {
    await viewModel.submitVocabResult();
    if (!mounted) return;

    showGameFinishDialog(
      context: context,
      correctCount: viewModel.correctCount,
      wrongCount: viewModel.wrongCount,
      onClose: () {
        Navigator.of(context).pop(); // close dialog
        Navigator.of(context).pop(); // back to selection
      },
      onReplay: () async {
        Navigator.of(context).pop(); // close dialog
        await viewModel.retryVocabGame(widget.userId!, widget.folderId!);
      },
      wrongWordsCount: viewModel.wrongCount,
      onRetryWrongWords:
          viewModel.wrongCount > 0
              ? () {
                Navigator.of(context).pop(); // close dialog
                viewModel.startWrongWordsRetry();
              }
              : null,
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
                      color: Theme.of(context).cardColor,
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color ??
                          const Color(0xFF333333),
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
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
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
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  AITaskContent(viewModel: viewModel),
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

  Widget _buildTranscriptView(ListeningViewModel viewModel) {
    final transcript = viewModel.aiContent?.transcript;
    if (transcript == null || transcript.isEmpty) {
      return const Center(
        child: Text(
          "Chưa có nội dung transcript",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SelectableText(
        transcript,
        style: TextStyle(
          fontSize: 16,
          height: 1.8,
          color:
              Theme.of(context).textTheme.bodyLarge?.color ??
              const Color(0xFF333333),
        ),
        contextMenuBuilder: (context, state) {
          final selectedText =
              state.textEditingValue.selection
                  .textInside(state.textEditingValue.text)
                  .trim();
          if (selectedText.isEmpty) return const SizedBox.shrink();

          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: state.contextMenuAnchors,
            buttonItems: [
              ContextMenuButtonItem(
                onPressed: () {
                  _showTranslationBottomSheet(selectedText);
                  state.hideToolbar();
                },
                label: 'Dịch',
              ),
              ...state.contextMenuButtonItems,
            ],
          );
        },
      ),
    );
  }

  void _showTranslationBottomSheet(String text) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => TranslationBottomSheet(
            text: text,
            translateWord: (val) => DictionaryService.translateWord(val),
          ),
    );
  }

  Widget _buildPlaybackControls(ListeningViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
                onPressed: viewModel.replay,
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
}
