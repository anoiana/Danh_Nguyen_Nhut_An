import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../api/auth_service.dart';
import '../../../core/widgets/speech_rate_slider.dart';
import '../view_model/reading_view_model.dart';
import 'dart:ui'; // For backdrop filter

class ReadingView extends StatefulWidget {
  final int folderId;
  final String folderName;
  final int level;
  final String topic;

  const ReadingView({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.level,
    required this.topic,
  });

  @override
  State<ReadingView> createState() => _ReadingViewState();
}

class _ReadingViewState extends State<ReadingView>
    with SingleTickerProviderStateMixin {
  final ReadingViewModel _viewModel = ReadingViewModel();
  static const Color primaryPink = Color(0xFFE91E63);
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel.init(
      folderId: widget.folderId,
      level: widget.level,
      topic: widget.topic,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ReadingViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isBusy) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: primaryPink),
              ),
            );
          }

          if (viewModel.isError) {
            return Scaffold(
              appBar: AppBar(leading: const BackButton(color: Colors.black)),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.grey,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        viewModel.errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (viewModel.content == null) {
            return const Scaffold(
              body: Center(child: Text("Không thể tải nội dung.")),
            );
          }

          return Scaffold(
            extendBodyBehindAppBar: true,
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildCustomHeader(viewModel),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildReadingTab(viewModel),
                              _buildQuestionTab(viewModel),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showPasteAndTranslateDialog(),
              backgroundColor: primaryPink,
              elevation: 4,
              child: const Icon(Icons.translate_rounded, color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomHeader(ReadingViewModel viewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: primaryPink,
                  ),
                ),
              ),
              const Text(
                'Đọc & Hiểu',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF333333),
                ),
              ),
              GestureDetector(
                onTap:
                    () => showSpeechRateBottomSheet(
                      context,
                      viewModel.ttsService,
                    ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.speed_rounded, color: primaryPink),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 48,
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
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.import_contacts_rounded, size: 18),
                    SizedBox(width: 8),
                    Text("Bài đọc"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_rounded, size: 18),
                    SizedBox(width: 8),
                    Text("Câu hỏi"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadingTab(ReadingViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
      itemCount: viewModel.paragraphs.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: SelectableText.rich(
            _buildStyledTextSpan(
              viewModel.paragraphs[index],
              viewModel.vocabularyInFolder,
            ),
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 18,
              height: 1.8,
              color: Color(0xFF444444),
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
                      viewModel.speak(selectedText);
                      state.hideToolbar();
                    },
                    label: 'Phát âm',
                  ),
                  ContextMenuButtonItem(
                    onPressed: () {
                      _showTranslationBottomSheet(selectedText);
                      state.hideToolbar();
                    },
                    label: 'Dịch',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuestionTab(ReadingViewModel viewModel) {
    if (viewModel.content == null || viewModel.content!.questions.isEmpty)
      return const SizedBox.shrink();

    final question =
        viewModel.content!.questions[viewModel.currentQuestionIndex];
    final progress =
        (viewModel.currentQuestionIndex + 1) /
        viewModel.content!.questions.length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Câu hỏi ${viewModel.currentQuestionIndex + 1}/${viewModel.content!.questions.length}',
              style: const TextStyle(
                color: primaryPink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                color: primaryPink,
                backgroundColor: Colors.pink.shade50,
                minHeight: 8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Text(
          question.question,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.4,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 32),

        ...question.options.map(
          (option) => _OptionCard(
            text: option,
            isSelected: viewModel.selectedOption == option,
            isCorrect: option == question.answer,
            isAnswered: viewModel.answered,
            onTap: () => viewModel.checkAnswer(option),
          ),
        ),

        const SizedBox(height: 40),

        if (viewModel.answered)
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (!viewModel.nextQuestion()) {
                  _showResultDialog(viewModel);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: primaryPink.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                viewModel.currentQuestionIndex <
                        viewModel.content!.questions.length - 1
                    ? 'Tiếp theo'
                    : 'Xem kết quả',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        const SizedBox(height: 40),
      ],
    );
  }

  TextSpan _buildStyledTextSpan(String text, List<String> vocabList) {
    final vocabSet = vocabList.map((v) => v.toLowerCase()).toSet();
    final spans = <TextSpan>[];
    final regex = RegExp(r"(\w+)|([^\w]+)");

    regex.allMatches(text).forEach((match) {
      final matchedText = match.group(0)!;
      final isWord = match.group(1) != null;
      if (isWord && vocabSet.contains(matchedText.toLowerCase())) {
        spans.add(
          TextSpan(
            text: matchedText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryPink,
              backgroundColor: primaryPink.withOpacity(0.05),
              decoration: TextDecoration.underline,
              decorationColor: primaryPink.withOpacity(0.5),
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: matchedText));
      }
    });
    return TextSpan(
      children: spans,
      style: const TextStyle(color: Colors.black87),
    );
  }

  void _showTranslationBottomSheet(String text) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => TranslationBottomSheet(text: text),
    );
  }

  void _showPasteAndTranslateDialog() {
    showDialog(
      context: context,
      builder: (context) => const PasteTranslateDialog(),
    );
  }

  void _showResultDialog(ReadingViewModel viewModel) {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Điểm số của bạn',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${viewModel.score}/${viewModel.content!.questions.length}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: primaryPink,
                    ),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _viewModel.init(
                          folderId: widget.folderId,
                          level: widget.level,
                          topic: widget.topic,
                        );
                      },
                      child: const Text('Luyện tập lại'),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final VoidCallback onTap;

  const _OptionCard({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade200;
    Color bgColor = Colors.white;
    Color iconColor = Colors.grey.shade400;
    IconData icon = Icons.circle_outlined;

    if (isAnswered) {
      if (isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.shade50;
        iconColor = Colors.green;
        icon = Icons.check_circle_rounded;
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.shade50;
        iconColor = Colors.red;
        icon = Icons.cancel_rounded;
      }
    } else if (isSelected) {
      borderColor = const Color(0xFFE91E63);
      bgColor = const Color(0xFFFCE4EC);
      iconColor = const Color(0xFFE91E63);
      icon = Icons.radio_button_checked_rounded;
    }

    return GestureDetector(
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width:
                isSelected || (isAnswered && (isCorrect || isSelected)) ? 2 : 1,
          ),
          boxShadow: [
            if (!isAnswered && !isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      (isAnswered && !isCorrect && isSelected)
                          ? Colors.red
                          : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isAnswered && isCorrect)
              const Icon(Icons.check_rounded, color: Colors.green),
          ],
        ),
      ),
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
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                );
              }
              return Text(
                snapshot.data ?? 'Lỗi khi dịch',
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

class PasteTranslateDialog extends StatefulWidget {
  const PasteTranslateDialog({super.key});
  @override
  State<PasteTranslateDialog> createState() => _PasteTranslateDialogState();
}

class _PasteTranslateDialogState extends State<PasteTranslateDialog> {
  final TextEditingController _controller = TextEditingController();
  String _result = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.translate_rounded, color: Color(0xFFE91E63)),
          SizedBox(width: 12),
          Text('Dịch nhanh'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Nhập hoặc dán văn bản để dịch...',
                filled: true,
                fillColor: const Color(0xFFFCE4EC).withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE91E63)),
                ),
              ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kết quả:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed:
              _isLoading
                  ? null
                  : () async {
                    if (_controller.text.isEmpty) return;
                    setState(() => _isLoading = true);
                    try {
                      final res = await AuthService.translateWord(
                        _controller.text,
                      );
                      setState(() => _result = res);
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Dịch ngay'),
        ),
      ],
    );
  }
}
