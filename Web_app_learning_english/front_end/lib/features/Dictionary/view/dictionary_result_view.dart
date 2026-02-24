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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DictionaryViewModel>().lookupWord(widget.word);
    });
  }

  Widget _buildTappableText(String text, {TextStyle? style}) {
    final defaultStyle = DefaultTextStyle.of(
      context,
    ).style.merge(style).copyWith(decoration: TextDecoration.none);
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

    return Text.rich(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final subtleColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Part of Speech Badge
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: primaryPink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryPink.withOpacity(0.2)),
          ),
          child: Text(
            meaning.partOfSpeech,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: primaryPink,
              fontSize: 16,
            ),
          ),
        ),

        // Definitions
        ...meaning.definitions.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final def = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number Badge
                Container(
                  margin: const EdgeInsets.only(top: 4, right: 16),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: primaryPink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryPink.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTappableText(
                        def.definition,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.5,
                          color:
                              isDark
                                  ? const Color(0xFFECEFF1)
                                  : const Color(0xFF263238),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (def.example != null && def.example!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 12.0),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: subtleColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDark
                                      ? Colors.white10
                                      : Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.format_quote_rounded,
                                    size: 20,
                                    color: primaryPink.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Example',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryPink.withOpacity(0.7),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildTappableText(
                                def.example!,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color:
                                      isDark
                                          ? const Color(0xFFB0BEC5)
                                          : const Color(0xFF546E7A),
                                  height: 1.5,
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
          );
        }),

        // Related Words
        if (meaning.synonyms.isNotEmpty || meaning.antonyms.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meaning.synonyms.isNotEmpty) ...[
                  _buildRelatedSection(
                    'Synonyms',
                    meaning.synonyms,
                    Colors.teal,
                    Icons.check_circle_outline_rounded,
                  ),
                  if (meaning.antonyms.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(
                        height: 1,
                        color:
                            isDark
                                ? Colors.white10
                                : Colors.grey.withOpacity(0.1),
                      ),
                    ),
                ],
                if (meaning.antonyms.isNotEmpty)
                  _buildRelatedSection(
                    'Antonyms',
                    meaning.antonyms,
                    Colors.redAccent,
                    Icons.cancel_outlined,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRelatedSection(
    String title,
    List<String> words,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              words.map((word) => _buildRelatedWordChip(word, color)).toList(),
        ),
      ],
    );
  }

  Widget _buildRelatedWordChip(String word, Color color) {
    return GestureDetector(
      onTap: () {
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Text(
          word,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
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
            centerTitle: true,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF80AB), Color(0xFFE91E63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showPasteAndTranslateDialog,
            backgroundColor: primaryPink,
            foregroundColor: Colors.white,
            elevation: 4,
            tooltip: 'Dịch nhanh',
            child: const Icon(Icons.translate_rounded),
          ),
          body: _buildBody(viewModel),
        );
      },
    );
  }

  Widget _buildBody(DictionaryViewModel viewModel) {
    if (viewModel.isBusy) {
      return const Center(child: CustomLoadingWidget(color: primaryPink));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (viewModel.state == ViewState.error || viewModel.entries.isEmpty) {
      final customEntry = DictionaryEntry(
        word: widget.word,
        meanings: [],
        phonetic: null,
        audioUrl: null,
      );
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryPink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: primaryPink,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Word not found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The word "${widget.word}" could not be found.\nWould you like to define it yourself?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _showSaveVocabDialog(customEntry),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Define & Save Custom Word'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                  shadowColor: primaryPink.withOpacity(0.4),
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
    return SelectionArea(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 24.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28.0),
              boxShadow: [
                BoxShadow(
                  color:
                      isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.white,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Word + Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.word,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: primaryPink,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          if (entry.phonetic != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.phonetic!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.8),
                                    fontSize: 16,
                                    fontFamily: 'RobotoMono',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (entry.audioUrl != null &&
                            entry.audioUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: IconButton.filledTonal(
                              icon: const Icon(Icons.volume_up_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: primaryPink.withOpacity(0.1),
                                foregroundColor: primaryPink,
                                padding: const EdgeInsets.all(12),
                              ),
                              tooltip: 'Listen to pronunciation',
                              onPressed:
                                  () => viewModel.playAudio(entry.audioUrl),
                            ),
                          ),
                        IconButton.filled(
                          icon: const Icon(Icons.bookmark_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: primaryPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                          ),
                          tooltip: 'Save to vocabulary',
                          onPressed: () => _showSaveVocabDialog(entry),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                  ),
                ),
                ...entry.meanings.map((m) => _buildMeaningWidget(m)),
              ],
            ),
          );
        },
      ),
    );
  }
}
