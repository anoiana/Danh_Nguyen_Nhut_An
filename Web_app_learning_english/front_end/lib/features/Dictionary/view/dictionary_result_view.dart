import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/dictionary_view_model.dart';
import '../model/dictionary_entry.dart';
import '../../Folders/model/folder.dart';
import '../../../core/base_view_model.dart';

import 'vocabulary_saving_dialog.dart';
import 'paste_translate_dialog.dart';
import '../../../core/widgets/custom_loading_widget.dart';

class DictionaryResultView extends StatefulWidget {
  final String word;
  final List<Folder> folders;

  const DictionaryResultView({
    super.key,
    required this.word,
    required this.folders,
  });

  @override
  _DictionaryResultViewState createState() => _DictionaryResultViewState();
}

class _DictionaryResultViewState extends State<DictionaryResultView> {
  // Định nghĩa màu sắc chủ đạo
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color lightPink = Color(0xFFF8BBD0);
  static const Color accentPink = Color(0xFFFF80AB);
  static const Color backgroundPink = Color(0xFFFCE4EC);
  static const Color darkTextColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DictionaryViewModel>().lookupWord(widget.word);
    });
  }

  // <<< CẬP NHẬT: CHO PHÉP BÔI ĐEN VÀ VẪN GIỮ CHỨC NĂNG TAP >>>
  SelectableText _buildTappableText(String text, {TextStyle? style}) {
    final defaultStyle = DefaultTextStyle.of(context).style.merge(style);
    final wordRegex = RegExp(r"([a-zA-Z'’]+)");
    List<TextSpan> textSpans = [];
    int lastMatchEnd = 0;

    wordRegex.allMatches(text).forEach((match) {
      if (match.start > lastMatchEnd) {
        textSpans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: defaultStyle,
          ),
        );
      }
      final String word = match.group(0)!;
      textSpans.add(
        TextSpan(
          text: word,
          style: defaultStyle,
          recognizer:
              TapGestureRecognizer()
                ..onTap = () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChangeNotifierProvider(
                            create: (_) => DictionaryViewModel(),
                            child: DictionaryResultView(
                              word: word,
                              folders: widget.folders,
                            ),
                          ),
                    ),
                  );
                },
        ),
      );
      lastMatchEnd = match.end;
    });

    if (lastMatchEnd < text.length) {
      textSpans.add(
        TextSpan(text: text.substring(lastMatchEnd), style: defaultStyle),
      );
    }

    return SelectableText.rich(
      TextSpan(children: textSpans),
      textAlign: TextAlign.justify,
    );
  }

  void _showPasteAndTranslateDialog() {
    showDialog(
      context: context,
      builder: (context) => const PasteTranslateDialog(),
    );
  }

  Future<void> _showSaveVocabDialog(DictionaryEntry entry) async {
    if (widget.folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn cần tạo thư mục trước khi lưu từ!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Capture the viewModel from the current context
    final viewModel = context.read<DictionaryViewModel>();

    // Use the extracted dialog widget
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => ChangeNotifierProvider.value(
            value: viewModel,
            child: VocabularySavingDialog(
              entry: entry,
              folders: widget.folders,
            ),
          ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Widget _buildMeaningWidget(Meaning meaning) {
    Widget buildSectionHeader(String title, IconData icon, Color color) {
      return Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = Theme.of(context).colorScheme.secondary;
    final textColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              meaning.partOfSpeech,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: primaryColor,
                fontSize: 18,
              ),
            ),
          ),
          buildSectionHeader('Định nghĩa', Icons.book_outlined, primaryColor),
          ...meaning.definitions.map((def) {
            int index = meaning.definitions.indexOf(def) + 1;
            return Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$index. ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Expanded(
                        child: _buildTappableText(
                          def.definition,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  if (def.example != null && def.example!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0, top: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vd: ',
                            style: TextStyle(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Expanded(
                            child: _buildTappableText(
                              '"${def.example!}"',
                              style: TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          if (meaning.synonyms.isNotEmpty) ...[
            buildSectionHeader(
              'Từ đồng nghĩa',
              Icons.swap_horiz_rounded,
              Colors.green.shade700,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children:
                    meaning.synonyms
                        .map(
                          (syn) => GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChangeNotifierProvider(
                                          create: (_) => DictionaryViewModel(),
                                          child: DictionaryResultView(
                                            word: syn,
                                            folders: widget.folders,
                                          ),
                                        ),
                                  ),
                                ),
                            child: Chip(
                              label: Text(syn),
                              backgroundColor: Colors.green.withOpacity(0.15),
                              side: BorderSide.none,
                              labelStyle: TextStyle(
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
          if (meaning.antonyms.isNotEmpty) ...[
            buildSectionHeader(
              'Từ trái nghĩa',
              Icons.compare_arrows_rounded,
              Colors.red.shade700,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children:
                    meaning.antonyms
                        .map(
                          (ant) => GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChangeNotifierProvider(
                                          create: (_) => DictionaryViewModel(),
                                          child: DictionaryResultView(
                                            word: ant,
                                            folders: widget.folders,
                                          ),
                                        ),
                                  ),
                                ),
                            child: Chip(
                              label: Text(ant),
                              backgroundColor: Colors.red.withOpacity(0.1),
                              side: BorderSide.none,
                              labelStyle: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DictionaryViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Kết quả: "${widget.word}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showPasteAndTranslateDialog,
            backgroundColor: Theme.of(context).primaryColor,
            tooltip: 'Dịch nhanh',
            child: const Icon(Icons.translate, color: Colors.white),
          ),
          body: _buildBody(viewModel),
        );
      },
    );
  }

  Widget _buildBody(DictionaryViewModel viewModel) {
    if (viewModel.isBusy) {
      return CustomLoadingWidget(color: Theme.of(context).primaryColor);
    }

    if (viewModel.state == ViewState.error || viewModel.entries.isEmpty) {
      final customEntry = DictionaryEntry(
        word: widget.word,
        meanings: [],
        phonetic: null,
        audioUrl: null,
      );
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy từ "${widget.word}" trong từ điển.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn có muốn tự định nghĩa và lưu từ này vào sổ tay của mình không?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showSaveVocabDialog(customEntry),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tự định nghĩa và Lưu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final entries = viewModel.entries;
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        entry.word,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    if (entry.phonetic != null)
                      Text(
                        entry.phonetic!,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                        ),
                      ),
                    if (entry.audioUrl != null && entry.audioUrl!.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.volume_up,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        ),
                        onPressed: () => viewModel.playAudio(entry.audioUrl),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.bookmark_add_outlined,
                        color: Theme.of(context).primaryColor,
                        size: 30,
                      ),
                      onPressed: () => _showSaveVocabDialog(entry),
                    ),
                  ],
                ),
                Divider(
                  height: 24,
                  thickness: 1.2,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                ...entry.meanings.map((m) => _buildMeaningWidget(m)),
              ],
            ),
          ),
        );
      },
    );
  }
}
