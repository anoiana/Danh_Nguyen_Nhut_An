import 'package:flutter/material.dart';
import '../api/auth_service.dart';
import '../api/tts_service.dart';

class ReadingGameScreen extends StatefulWidget {
  final ReadingContent content;
  final List<String> vocabularyInFolder;

  const ReadingGameScreen({
    Key? key,
    required this.content,
    required this.vocabularyInFolder,
  }) : super(key: key);

  @override
  State<ReadingGameScreen> createState() => _ReadingGameScreenState();
}

class _ReadingGameScreenState extends State<ReadingGameScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _answered = false;
  String? _selectedOption;
  late final List<String> _paragraphs;
  final TextToSpeechService _ttsService = TextToSpeechService();
  static const Color primaryPink = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _paragraphs = _splitTextIntoParagraphs(widget.content.story);
    _ttsService.init();
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  void _checkAnswer(String option) {
    if (_answered) return;
    setState(() {
      _selectedOption = option;
      _answered = true;
      if (option == widget.content.questions[_currentQuestionIndex].answer) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.content.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _selectedOption = null;
      });
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.celebration_rounded, color: primaryPink, size: 28),
              SizedBox(width: 12),
              Text('Hoàn thành!'),
            ],
          ),
          content: Text(
            'Bạn đã trả lời đúng $_score/${widget.content.questions.length} câu.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Đóng dialog
                Navigator.of(context).pop(); // Quay về màn hình trước đó
              },
              child: const Text('OK', style: TextStyle(color: primaryPink, fontWeight: FontWeight.bold)),
            ),
          ],
        ));
  }

  void _showTranslationBottomSheet(String text) {
    _ttsService.stop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: FutureBuilder<String>(
              future: AuthService.translateWord(text),
              builder: (context, snapshot) {
                Widget translationContent;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  translationContent = const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator(color: primaryPink)),
                  );
                } else if (snapshot.hasError) {
                  translationContent = Text(
                    'Lỗi khi dịch.',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  );
                } else {
                  translationContent = Text(
                    snapshot.data ?? 'Không có bản dịch.',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                    textAlign: TextAlign.center,
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // <<< START: THAY ĐỔI Ở ĐÂY >>>
                    // Bọc Text và Icon vào một Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Giới hạn chiều rộng của Text để Icon không bị đẩy ra xa
                        Flexible(
                          child: Text(
                            '"$text"',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Thêm Icon phát âm
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: primaryPink),
                          tooltip: 'Phát âm từ gốc',
                          onPressed: () {
                            _ttsService.stop().then((_) {
                              _ttsService.setSpeechRate(0.5); // Tốc độ bình thường
                              _ttsService.speak(text);
                            });
                          },
                        ),
                      ],
                    ),
                    // <<< END: THAY ĐỔI Ở ĐÂY >>>
                    const Divider(height: 32, thickness: 1),
                    translationContent,
                    const SizedBox(height: 10),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showPasteAndTranslateDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Sử dụng một widget riêng để quản lý state của dialog
        return const _PasteTranslateDialog();
      },
    );
  }

  TextSpan _buildStyledTextSpan(String paragraphText, {required TextStyle defaultStyle}) {
    final Set<String> vocabSet = widget.vocabularyInFolder.map((v) => v.toLowerCase()).toSet();
    final List<TextSpan> spans = [];
    final RegExp wordAndNonWordRegex = RegExp(r"(\w+)|([^\w]+)");

    wordAndNonWordRegex.allMatches(paragraphText).forEach((match) {
      final String? matchedText = match.group(0);
      if (matchedText == null) return;

      final bool isWord = match.group(1) != null;
      if (isWord) {
        spans.add(
          TextSpan(
            text: matchedText,
            style: vocabSet.contains(matchedText.toLowerCase())
                ? const TextStyle(fontWeight: FontWeight.bold, color: primaryPink, decoration: TextDecoration.underline, decorationColor: Color(0xAAE91E63))
                : null,
          ),
        );
      } else {
        spans.add(TextSpan(text: matchedText));
      }
    });

    return TextSpan(style: defaultStyle, children: spans);
  }

  List<String> _splitTextIntoParagraphs(String text, {int sentencesPerParagraph = 3}) {
    if (text.isEmpty) return [];
    final List<String> sentences = text.split(RegExp(r'(?<=[.?!])\s+'));
    if (sentences.length <= sentencesPerParagraph) return [text];
    final List<String> paragraphs = [];
    for (var i = 0; i < sentences.length; i += sentencesPerParagraph) {
      var end = (i + sentencesPerParagraph < sentences.length) ? i + sentencesPerParagraph : sentences.length;
      paragraphs.add(sentences.sublist(i, end).join(' ').trim());
    }
    return paragraphs.where((p) => p.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Đọc & Trả lời', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 1,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
            tabs: [
              Tab(
                icon: Icon(Icons.article_outlined, color: Colors.white),
                child: Text(
                  "Bài đọc",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Tab(
                icon: Icon(Icons.question_answer_outlined, color: Colors.white),
                child: Text(
                  "Câu hỏi",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        // <<< START: THÊM FLOATING ACTION BUTTON MỚI >>>
        floatingActionButton: FloatingActionButton(
          onPressed: _showPasteAndTranslateDialog,
          backgroundColor: primaryPink,
          tooltip: 'Dịch văn bản',
          child: const Icon(Icons.translate, color: Colors.white),
        ),
        // <<< END: THÊM FLOATING ACTION BUTTON MỚI >>>
        body: TabBarView(
          children: [
            _buildReadingTab(),
            _buildQuestionTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingTab() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: SelectionArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            itemCount: _paragraphs.length,
            itemBuilder: (context, index) {
              final paragraph = _paragraphs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: SelectableText.rich(
                  _buildStyledTextSpan(
                    paragraph,
                    defaultStyle: const TextStyle(fontSize: 18, height: 1.7, color: Color(0xFF333333)),
                  ),
                  textAlign: TextAlign.justify,
                  contextMenuBuilder: (context, editableTextState) {
                    final TextEditingValue value = editableTextState.textEditingValue;
                    final String selectedText = value.selection.textInside(value.text).trim();

                    if (selectedText.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: <ContextMenuButtonItem>[
                        ContextMenuButtonItem(
                          onPressed: () {
                            _ttsService.speak(selectedText);
                            editableTextState.hideToolbar();
                          },
                          label: 'Phát âm',
                        ),
                        ContextMenuButtonItem(
                          onPressed: () {
                            _showTranslationBottomSheet(selectedText);
                            editableTextState.hideToolbar();
                          },
                          label: 'Dịch',
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionTab() {
    final currentQuestion = widget.content.questions[_currentQuestionIndex];
    final progressValue = (_currentQuestionIndex + 1) / widget.content.questions.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          children: [
            // Phần tiến trình (Không thay đổi)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Câu hỏi ${_currentQuestionIndex + 1}/${widget.content.questions.length}',
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        backgroundColor: primaryPink.withOpacity(0.2),
                        color: primaryPink,
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Phần câu hỏi (Không thay đổi)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
              ),
              child: Text(
                currentQuestion.question,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),

            // <<< THAY ĐỔI LỚN: SỬ DỤNG LAYOUTBUILDER ĐỂ TẠO GRID ĐÁP ỨNG >>>
            LayoutBuilder(
              builder: (context, constraints) {
                // Xác định số cột dựa trên chiều rộng khả dụng
                const double breakpoint = 600;
                final int crossAxisCount = constraints.maxWidth < breakpoint ? 1 : 2;
                const double spacing = 16.0;

                // Tính toán chiều rộng cho mỗi item
                final double itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: currentQuestion.options.map((option) {
                    return _OptionCard(
                      text: option,
                      isSelected: _selectedOption == option,
                      isCorrect: option == currentQuestion.answer,
                      isAnswered: _answered,
                      width: itemWidth,
                      onTap: () => _checkAnswer(option),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 28),

            // Phần nút "Tiếp theo" (Cải thiện style)
            Visibility(
              visible: _answered,
              child: SizedBox(
                width: double.infinity,
                height: 52, // Chiều cao cố định cho nút
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPink,
                    foregroundColor: Colors.white, // Màu chữ
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: primaryPink.withOpacity(0.4),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: Text(
                    _currentQuestionIndex < widget.content.questions.length - 1 ? 'Câu tiếp theo' : 'Xem kết quả',
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

class _PasteTranslateDialog extends StatefulWidget {
  const _PasteTranslateDialog({Key? key}) : super(key: key);

  @override
  State<_PasteTranslateDialog> createState() => _PasteTranslateDialogState();
}

class _PasteTranslateDialogState extends State<_PasteTranslateDialog> {
  final TextEditingController _textController = TextEditingController();
  String _translationResult = '';
  String? _errorMessage;
  bool _isLoading = false;
  final TextToSpeechService _ttsService = TextToSpeechService(); // <<< THÊM TTS SERVICE >>>

  static const Color primaryPink = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _ttsService.init(); // Khởi tạo service
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    final textToTranslate = _textController.text.trim();
    if (textToTranslate.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _translationResult = '';
    });

    try {
      final result = await AuthService.translateWord(textToTranslate);
      setState(() => _translationResult = result);
    } catch (e) {
      setState(() => _errorMessage = 'Đã xảy ra lỗi khi dịch. Vui lòng thử lại.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.translate_rounded, color: primaryPink),
          SizedBox(width: 12),
          Text('Dịch văn bản'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // <<< START: THAY ĐỔI Ở ĐÂY >>>
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 5,
                    minLines: 3,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Dán hoặc nhập văn bản...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryPink, width: 2)),
                    ),
                  ),
                ),
                // Thêm icon loa để đọc text trong ô input
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.grey),
                  tooltip: 'Phát âm văn bản gốc',
                  onPressed: () {
                    final textToSpeak = _textController.text.trim();
                    if (textToSpeak.isNotEmpty) {
                      _ttsService.stop().then((_) {
                        _ttsService.setSpeechRate(0.5);
                        _ttsService.speak(textToSpeak);
                      });
                    }
                  },
                )
              ],
            ),
            // <<< END: THAY ĐỔI Ở ĐÂY >>>
            const SizedBox(height: 16),
            if (_isLoading) const Center(child: CircularProgressIndicator(color: primaryPink)),
            if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14)),
            if (_translationResult.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bản dịch:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                    const SizedBox(height: 4),
                    Text(_translationResult, style: TextStyle(fontSize: 16, color: Colors.blue.shade900)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(child: const Text('Đóng'), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryPink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: _isLoading ? null : _translate,
          child: const Text('Dịch'),
        ),
      ],
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final VoidCallback onTap;
  final double width;

  const _OptionCard({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.onTap,
    required this.width,
  }) : super(key: key);

  static const Color primaryPink = Color(0xFFE91E63);

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.grey.shade300;
    Color? tileColor = Colors.white;
    Icon? trailingIcon;
    double elevation = 2.0;

    if (isAnswered) {
      if (isCorrect) {
        borderColor = Colors.green;
        tileColor = Colors.green.shade50;
        trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
      } else if (isSelected) {
        borderColor = Colors.red;
        tileColor = Colors.red.shade50;
        trailingIcon = const Icon(Icons.cancel, color: Colors.red);
      }
      elevation = 1.0;
    } else if (isSelected) {
      // Trạng thái khi người dùng đã chọn nhưng chưa xem đáp án
      borderColor = primaryPink;
      elevation = 4.0;
    }

    return SizedBox(
      width: width,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: tileColor,
          border: Border.all(color: borderColor, width: 2.0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected ? primaryPink.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: trailingIcon != null
                        ? Padding(
                      key: ValueKey(trailingIcon.icon),
                      padding: const EdgeInsets.only(left: 12),
                      child: trailingIcon,
                    )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
