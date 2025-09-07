// lib/screens/listening_game_screen.dart

import 'package:flutter/material.dart';
import 'package:untitled/api/auth_service.dart';
import 'package:untitled/api/tts_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class ListeningGameScreen extends StatefulWidget {
  final ListeningContent content;
  final int level;
  final String gameSubType;

  const ListeningGameScreen({
    Key? key,
    required this.content,
    required this.level,
    required this.gameSubType,
  }) : super(key: key);

  @override
  _ListeningGameScreenState createState() => _ListeningGameScreenState();
}

class _ListeningGameScreenState extends State<ListeningGameScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextToSpeechService _ttsService = TextToSpeechService();
  final ScrollController _scrollController = ScrollController();

  // State
  bool _isPlaying = false;
  double _progress = 0.0;
  late StreamSubscription<bool> _isPlayingSubscription;
  late StreamSubscription<double> _progressSubscription;
  bool _isSubmitted = false;
  late List<String?> _selectedMcqOptions;
  late List<bool?> _mcqResults;
  int _mcqScore = 0;
  late List<TextEditingController> _fitbControllers;
  late List<FocusNode> _fitbFocusNodes;
  late List<bool?> _fitbResults;
  int _fitbScore = 0;
  late final TextSpan _styledTranscript;

  static const Color primaryPink = Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupTtsAndListeners();
    _setupTasks();
    _styledTranscript = _buildStyledTranscript(widget.content.transcript);
  }

  void _setupTtsAndListeners() {
    _ttsService.init().then((_) => _setTtsSpeed());
    _isPlayingSubscription = _ttsService.isPlayingStream.listen((isPlaying) {
      if (mounted) setState(() => _isPlaying = isPlaying);
    });
    _progressSubscription = _ttsService.progressStream.listen((progress) {
      if (mounted) setState(() => _progress = progress);
    });
  }

  void _setupTasks() {
    _selectedMcqOptions = List.filled(widget.content.mcq.length, null);
    _mcqResults = List.filled(widget.content.mcq.length, null);

    if (widget.content.fitb != null && widget.content.fitb!.answers.isNotEmpty) {
      final int blankCount = widget.content.fitb!.answers.length;
      _fitbControllers = List.generate(blankCount, (_) => TextEditingController());
      _fitbFocusNodes = List.generate(blankCount, (_) => FocusNode());
      _fitbResults = List.filled(blankCount, null);
    } else {
      _fitbControllers = [];
      _fitbFocusNodes = [];
      _fitbResults = [];
    }

    setState(() {
      _isSubmitted = false;
      _mcqScore = 0;
      _fitbScore = 0;
    });
  }

  void _setTtsSpeed() {
    double rate = 0.5;
    switch (widget.level) {
      case 1: rate = 0.45; break;
      case 2: rate = 0.6; break;
      case 3: rate = 0.7; break;
    }
    _ttsService.setSpeechRate(rate);
  }

  @override
  void dispose() {
    _ttsService.stop();
    _isPlayingSubscription.cancel();
    _progressSubscription.cancel();
    _tabController.dispose();
    _scrollController.dispose();
    for (var controller in _fitbControllers) {
      controller.dispose();
    }
    for (var focusNode in _fitbFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _ttsService.stop();
    } else {
      if (_progress >= 1.0) _progress = 0.0;
      _ttsService.speak(widget.content.transcript);
    }
  }

  void _replay() {
    _ttsService.stop();
    Future.delayed(const Duration(milliseconds: 100), () {
      _progress = 0;
      _ttsService.speak(widget.content.transcript);
    });
  }

  void _onMcqOptionSelected(int questionIndex, String option) {
    if (_isSubmitted) return;
    setState(() => _selectedMcqOptions[questionIndex] = option);
  }

  void _checkAllAnswers() {
    if (widget.gameSubType == 'mcq') {
      int mcqCorrect = 0;
      for (int i = 0; i < widget.content.mcq.length; i++) {
        bool isCorrect = _selectedMcqOptions[i] == widget.content.mcq[i].answer;
        if (isCorrect) mcqCorrect++;
        _mcqResults[i] = isCorrect;
      }
      setState(() => _mcqScore = mcqCorrect);
    } else if (widget.gameSubType == 'fitb' && widget.content.fitb != null) {
      int fitbCorrect = 0;
      for (int i = 0; i < _fitbControllers.length; i++) {
        bool isCorrect = _fitbControllers[i].text.trim().toLowerCase() ==
            widget.content.fitb!.answers[i].toLowerCase();
        if (isCorrect) fitbCorrect++;
        _fitbResults[i] = isCorrect;
      }
      setState(() => _fitbScore = fitbCorrect);
    }

    setState(() => _isSubmitted = true);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  void _resetGame() {
    _setupTasks();
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                  translationContent = Text('Lỗi khi dịch.',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                      textAlign: TextAlign.center);
                } else {
                  translationContent = Text(snapshot.data ?? 'Không có bản dịch.',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                      textAlign: TextAlign.center);
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12))),
                    const SizedBox(height: 20),
                    // <<< START: THAY ĐỔI Ở ĐÂY >>>
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '"$text"',
                            style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: primaryPink),
                          tooltip: 'Phát âm từ gốc',
                          onPressed: () {
                            _ttsService.stop().then((_) {
                              _ttsService.setSpeechRate(0.5);
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
        return const _PasteTranslateDialog();
      },
    );
  }

  TextSpan _buildStyledTranscript(String text) {
    final List<TextSpan> children = [];
    final RegExp speakerRegex = RegExp(r'^(Man:|Woman:|Narrator:|Speaker \d+:)', multiLine: true);

    final defaultStyle = const TextStyle(fontSize: 17, height: 1.6, color: Colors.black, fontWeight: FontWeight.normal);
    final boldStyle = defaultStyle.copyWith(fontWeight: FontWeight.bold);

    int lastMatchEnd = 0;
    for (final match in speakerRegex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      children.add(TextSpan(text: match.group(0), style: boldStyle));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      children.add(TextSpan(text: text.substring(lastMatchEnd)));
    }
    return TextSpan(style: defaultStyle, children: children);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth > 800;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.gameSubType == 'mcq' ? 'Nghe - Trắc nghiệm' : 'Nghe - Điền từ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: primaryPink,
            foregroundColor: Colors.white,
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(icon: Icon(Icons.question_answer, color: Colors.white), child: Text("Bài tập", style: TextStyle(color: Colors.white))),
                Tab(icon: Icon(Icons.article, color: Colors.white), child: Text("Transcript", style: TextStyle(color: Colors.white))),
              ],
            ),
          ),
          floatingActionButton: kIsWeb
              ? FloatingActionButton(
            onPressed: _showPasteAndTranslateDialog,
            backgroundColor: primaryPink,
            tooltip: 'Dịch văn bản',
            child: const Icon(Icons.translate, color: Colors.white),
          )
              : null,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: TabBarView(
                controller: _tabController,
                children: [_buildTaskView(isWideScreen), _buildTranscriptView()],
              ),
            ),
          ),
          bottomNavigationBar: _buildPlaybackControls(),
        );
      },
    );
  }

  Widget _buildPlaybackControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -4))]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress, backgroundColor: primaryPink.withOpacity(0.2), valueColor: const AlwaysStoppedAnimation<Color>(primaryPink), minHeight: 6),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.replay), iconSize: 28, color: Colors.black54, tooltip: "Phát lại từ đầu", onPressed: _replay),
              const SizedBox(width: 24),
              IconButton(icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 60, color: primaryPink), onPressed: _togglePlayPause),
              const SizedBox(width: 24),
              IconButton(icon: const Icon(Icons.stop_circle_outlined), iconSize: 28, color: Colors.black54, tooltip: "Dừng", onPressed: () => _ttsService.stop()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskView(bool isWideScreen) {
    final bool hasFitb = widget.content.fitb != null && widget.content.fitb!.answers.isNotEmpty;
    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 24.0 : 16.0, vertical: 20.0),
      children: [
        if (_isSubmitted)
          Card(
            color: Colors.blue.shade50,
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Kết quả", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 12),
                  if (widget.gameSubType == 'mcq')
                    Text("Bạn đã trả lời đúng $_mcqScore/${widget.content.mcq.length} câu", style: const TextStyle(fontSize: 16)),
                  if (widget.gameSubType == 'fitb' && hasFitb)
                    Text("Bạn đã điền đúng $_fitbScore/${widget.content.fitb!.answers.length} từ", style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),

        if (widget.gameSubType == 'mcq') ...[
          _buildSectionHeader("Câu hỏi trắc nghiệm", Icons.checklist_rtl),
          ...widget.content.mcq.asMap().entries.map((entry) {
            int idx = entry.key;
            ListeningMCQ question = entry.value;
            return _buildSingleMcqCard(question, idx);
          }),
        ],

        if (widget.gameSubType == 'fitb' && hasFitb) ...[
          _buildSectionHeader("Điền vào chỗ trống", Icons.edit_note),
          _buildFitbCard(),
        ],

        const SizedBox(height: 40),
        _buildBottomButtons(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBottomButtons() {
    if (!_isSubmitted) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_outline),
          label: const Text("Nộp Bài"),
          onPressed: _checkAllAnswers,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Làm Lại"),
              onPressed: _resetGame,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryPink,
                side: const BorderSide(color: primaryPink),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.exit_to_app),
              label: const Text("Kết Thúc"),
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(children: [Icon(icon, color: primaryPink), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _buildSingleMcqCard(ListeningMCQ question, int index) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Câu ${index + 1}: ${question.question}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            ...question.options.map((option) {
              bool isSelected = _selectedMcqOptions[index] == option;
              bool isCorrectAnswer = option == question.answer;
              Color? tileColor;
              Icon? trailingIcon;
              if (_isSubmitted) {
                if (isCorrectAnswer) {
                  tileColor = Colors.green.withOpacity(0.15);
                  trailingIcon = const Icon(Icons.check_circle, color: Colors.green);
                } else if (isSelected) {
                  tileColor = Colors.red.withOpacity(0.15);
                  trailingIcon = const Icon(Icons.cancel, color: Colors.red);
                }
              }

              return InkWell(
                onTap: () => _onMcqOptionSelected(index, option),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: tileColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected && !_isSubmitted ? primaryPink : Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Radio<String>(value: option, groupValue: _selectedMcqOptions[index], onChanged: (val) => _onMcqOptionSelected(index, val!), activeColor: primaryPink),
                      Expanded(child: Text(option)),
                      if (trailingIcon != null) trailingIcon,
                    ],
                  ),
                ),
              );
            }).toList(),
            if (_isSubmitted && _mcqResults[index] == false)
              Padding(
                padding: const EdgeInsets.only(top: 12.0, left: 16),
                child: Text(
                  "Đáp án đúng: ${question.answer}",
                  style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildFitbCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hoàn thành các câu sau:", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black)),
            const SizedBox(height: 16),
            _buildFitbRichText(),
          ],
        ),
      ),
    );
  }

  Widget _buildFitbRichText() {
    final textParts = widget.content.fitb!.textWithBlanks.split(RegExp(r'____\(\d+\)____'));
    final List<InlineSpan> children = [];
    for (int i = 0; i < textParts.length; i++) {
      children.add(TextSpan(
        text: textParts[i],
        style: const TextStyle(fontSize: 17, height: 2.2, color: Colors.black, fontWeight: FontWeight.normal),
      ));
      if (i < _fitbControllers.length) {
        final bool isWrong = _isSubmitted && _fitbResults[i] == false;
        children.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _fitbControllers[i],
                  focusNode: _fitbFocusNodes[i],
                  readOnly: _isSubmitted,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    filled: _isSubmitted,
                    fillColor: (_fitbResults[i] ?? true) ? Colors.green.shade50 : Colors.red.shade50,
                    hintText: '(${i + 1})',
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: primaryPink, width: 2)),
                  ),
                ),
              ),
              if (isWrong)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Đúng: ${widget.content.fitb!.answers[i]}",
                    style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ));
      }
    }
    return RichText(text: TextSpan(children: children));
  }

  Widget _buildTranscriptView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: SelectableText.rich(
        _styledTranscript,
        key: const Key('transcript_text'),
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
                  _ttsService.stop().then((_) {
                    _ttsService.speak(selectedText);
                  });
                  editableTextState.hideToolbar();
                },
                label: 'Phát âm',
              ),
              ContextMenuButtonItem(
                onPressed: () {
                  _ttsService.stop();
                  // <<< DÒNG ĐÃ ĐƯỢC BỎ COMMENT >>>
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