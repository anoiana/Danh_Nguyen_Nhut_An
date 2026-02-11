import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../model/vocabulary.dart';
import '../view_model/vocabulary_detail_view_model.dart';
import '../../Dictionary/model/dictionary_entry.dart';
import '../../../core/widgets/custom_loading_widget.dart';

class VocabularyDetailView extends StatefulWidget {
  final Vocabulary vocabulary;

  const VocabularyDetailView({Key? key, required this.vocabulary})
    : super(key: key);

  @override
  _VocabularyDetailViewState createState() => _VocabularyDetailViewState();
}

class _VocabularyDetailViewState extends State<VocabularyDetailView> {
  // Định nghĩa màu sắc chủ đạo
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color accentPink = Color(0xFFFF80AB);
  static const Color backgroundPink = Color(0xFFFCE4EC);
  static const Color darkTextColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocabularyDetailViewModel>().init(widget.vocabulary);
    });
  }

  void _showTranslationBottomSheet(
    String text,
    VocabularyDetailViewModel viewModel,
  ) {
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
              future: viewModel.translate(text),
              builder: (context, snapshot) {
                Widget translationContent;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  translationContent = const SizedBox(
                    height: 50,
                    child: Center(
                      child: CustomLoadingWidget(color: primaryPink, size: 40),
                    ),
                  );
                } else if (snapshot.hasError) {
                  translationContent = Text(
                    'Lỗi khi dịch.',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                    textAlign: TextAlign.center,
                  );
                } else {
                  translationContent = Text(
                    snapshot.data ?? 'Không có bản dịch.',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '"$text"',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.grey),
                          tooltip: 'Phát âm từ gốc',
                          onPressed: () => viewModel.speak(text),
                        ),
                      ],
                    ),
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

  Widget _buildContextMenu(
    BuildContext context,
    EditableTextState editableTextState,
    VocabularyDetailViewModel viewModel,
  ) {
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
            viewModel.speak(selectedText);
            editableTextState.hideToolbar();
          },
          label: 'Phát âm',
        ),
        ContextMenuButtonItem(
          onPressed: () {
            _showTranslationBottomSheet(selectedText, viewModel);
            editableTextState.hideToolbar();
          },
          label: 'Dịch',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VocabularyDetailViewModel>(
      builder: (context, viewModel, child) {
        final vocab = widget.vocabulary;
        final isLargeScreen = MediaQuery.of(context).size.width > 600;

        return Scaffold(
          backgroundColor: backgroundPink,
          appBar: AppBar(
            title: Text(
              vocab.word,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: primaryPink,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          floatingActionButton:
              kIsWeb
                  ? FloatingActionButton(
                    onPressed: _showPasteAndTranslateDialog,
                    backgroundColor: primaryPink,
                    tooltip: 'Dịch văn bản',
                    child: const Icon(Icons.translate, color: Colors.white),
                  )
                  : null,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final padding = isLargeScreen ? 32.0 : 16.0;
              final maxImageWidth =
                  isLargeScreen ? 500.0 : constraints.maxWidth - padding * 2;

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vocab.userImageBase64 != null &&
                              vocab.userImageBase64!.isNotEmpty)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: isLargeScreen ? 32.0 : 24.0,
                                ),
                                child: Hero(
                                  tag: 'vocab-image-${vocab.id}',
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16.0),
                                    child: Builder(
                                      builder: (context) {
                                        try {
                                          final imageBytes = base64Decode(
                                            vocab.userImageBase64!,
                                          );
                                          return Container(
                                            constraints: BoxConstraints(
                                              maxWidth: maxImageWidth,
                                            ),
                                            child: Image.memory(
                                              imageBytes,
                                              fit: BoxFit.contain,
                                              frameBuilder: (
                                                context,
                                                child,
                                                frame,
                                                wasSynchronouslyLoaded,
                                              ) {
                                                if (wasSynchronouslyLoaded)
                                                  return child;
                                                return AnimatedOpacity(
                                                  opacity:
                                                      frame == null ? 0 : 1,
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeOut,
                                                  child: child,
                                                );
                                              },
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => _buildImageError(
                                                    maxImageWidth,
                                                  ),
                                            ),
                                          );
                                        } catch (e) {
                                          return _buildImageError(
                                            maxImageWidth,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  vocab.word,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryPink,
                                    fontSize: isLargeScreen ? 32 : 28,
                                  ),
                                ),
                              ),
                              if (vocab.phoneticText != null)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isLargeScreen ? 12.0 : 8.0,
                                  ),
                                  child: Text(
                                    vocab.phoneticText!,
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 20 : 18,
                                      color: accentPink,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              if (vocab.audioUrl != null &&
                                  vocab.audioUrl!.isNotEmpty)
                                IconButton(
                                  icon: Icon(
                                    Icons.volume_up,
                                    size: isLargeScreen ? 36 : 32,
                                    color: primaryPink,
                                  ),
                                  tooltip: 'Phát âm thanh',
                                  onPressed:
                                      () => viewModel.playAudio(vocab.audioUrl),
                                ),
                            ],
                          ),
                          Divider(
                            height: isLargeScreen ? 40 : 32,
                            thickness: 1.5,
                            color: accentPink.withOpacity(0.5),
                          ),
                          if (vocab.userDefinedMeaning != null &&
                              vocab.userDefinedMeaning!.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Nghĩa của bạn',
                              Icons.lightbulb_outline_rounded,
                              isLargeScreen,
                            ),
                            _buildUserMeaning(
                              vocab.userDefinedMeaning!,
                              viewModel,
                            ),
                          ],
                          if (vocab.meanings != null &&
                              vocab.meanings!.isNotEmpty) ...[
                            Divider(
                              height: isLargeScreen ? 40 : 32,
                              thickness: 1.5,
                              color: accentPink.withOpacity(0.5),
                            ),
                            _buildSectionHeader(
                              'Chi tiết từ điển',
                              Icons.menu_book_rounded,
                              isLargeScreen,
                            ),
                            const SizedBox(height: 8),
                            ...vocab.meanings!.map(
                              (Meaning meaning) => _buildMeaningWidget(
                                meaning,
                                isLargeScreen,
                                viewModel,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isLargeScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLargeScreen ? 12.0 : 8.0),
      child: Row(
        children: [
          Icon(icon, size: isLargeScreen ? 28 : 24, color: primaryPink),
          SizedBox(width: isLargeScreen ? 16 : 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: darkTextColor,
              fontSize: isLargeScreen ? 24 : 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMeaning(
    String meaning,
    VocabularyDetailViewModel viewModel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        color: accentPink.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentPink.withOpacity(0.3)),
      ),
      child: SelectableText(
        '"$meaning"',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontStyle: FontStyle.italic,
          color: primaryPink.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
        contextMenuBuilder:
            (context, state) => _buildContextMenu(context, state, viewModel),
      ),
    );
  }

  Widget _buildMeaningWidget(
    Meaning meaning,
    bool isLargeScreen,
    VocabularyDetailViewModel viewModel,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meaning.partOfSpeech,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                color: primaryPink,
                fontSize: isLargeScreen ? 22 : 20,
              ),
            ),
            const Divider(height: 24, thickness: 1, color: backgroundPink),
            ...meaning.definitions.map((def) {
              int index = meaning.definitions.indexOf(def) + 1;
              return Padding(
                padding: EdgeInsets.only(top: isLargeScreen ? 12.0 : 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: isLargeScreen ? 18 : 16,
                          color: darkTextColor,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: '$index. ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: def.definition),
                        ],
                      ),
                      contextMenuBuilder:
                          (context, state) =>
                              _buildContextMenu(context, state, viewModel),
                    ),
                    if (def.example != null && def.example!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          left: 18.0,
                          top: isLargeScreen ? 8.0 : 6.0,
                        ),
                        child: SelectableText(
                          'Vd: "${def.example!}"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey.shade700,
                            fontSize: isLargeScreen ? 16 : 14,
                          ),
                          contextMenuBuilder:
                              (context, state) =>
                                  _buildContextMenu(context, state, viewModel),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            if (meaning.synonyms.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, size: 18, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    "Đồng nghĩa",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      meaning.synonyms
                          .map(
                            (syn) => Chip(
                              label: Text(syn),
                              backgroundColor: Colors.green.withOpacity(0.15),
                              side: BorderSide.none,
                              labelStyle: TextStyle(
                                color: Colors.green.shade800,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
            if (meaning.antonyms.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(
                    Icons.compare_arrows_rounded,
                    size: 18,
                    color: Colors.red,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Trái nghĩa",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children:
                      meaning.antonyms
                          .map(
                            (ant) => Chip(
                              label: Text(ant),
                              backgroundColor: Colors.red.withOpacity(0.1),
                              side: BorderSide.none,
                              labelStyle: TextStyle(color: Colors.red.shade800),
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageError(double maxImageWidth) {
    return Container(
      width: maxImageWidth,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 60),
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

  static const Color primaryPink = Color(0xFFE91E63);

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
      final result = await context.read<VocabularyDetailViewModel>().translate(
        textToTranslate,
      );
      setState(() => _translationResult = result);
    } catch (e) {
      setState(
        () => _errorMessage = 'Đã xảy ra lỗi khi dịch. Vui lòng thử lại.',
      );
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryPink,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.grey),
                  tooltip: 'Phát âm văn bản gốc',
                  onPressed: () {
                    final textToSpeak = _textController.text.trim();
                    if (textToSpeak.isNotEmpty) {
                      context.read<VocabularyDetailViewModel>().speak(
                        textToSpeak,
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: CustomLoadingWidget(color: primaryPink, size: 60),
              ),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            if (_translationResult.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bản dịch:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _translationResult,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Đóng'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryPink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isLoading ? null : _translate,
          child: const Text('Dịch'),
        ),
      ],
    );
  }
}
