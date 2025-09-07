import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:audioplayers/audioplayers.dart';
import '../api/auth_service.dart';
import '../api/image_upload_service.dart';
import '../widgets/draggable_image_editor.dart';


class DictionaryResultScreen extends StatefulWidget {
  final String word;
  final List<Folder> folders;

  const DictionaryResultScreen({super.key, required this.word, required this.folders});

  @override
  _DictionaryResultScreenState createState() => _DictionaryResultScreenState();
}

class _DictionaryResultScreenState extends State<DictionaryResultScreen> {
  late Future<List<DictionaryEntry>> _lookupFuture;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Định nghĩa màu sắc chủ đạo
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color lightPink = Color(0xFFF8BBD0);
  static const Color accentPink = Color(0xFFFF80AB);
  static const Color backgroundPink = Color(0xFFFCE4EC);
  static const Color darkTextColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _lookupFuture = AuthService.lookupWord(widget.word);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }


  Future<void> _playAudio(String? url) async {
    if (url != null && url.isNotEmpty) {
      try {
        await _audioPlayer.play(UrlSource(url));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể phát âm thanh.')));
        }
      }
    }
  }

  // <<< CẬP NHẬT: CHO PHÉP BÔI ĐEN VÀ VẪN GIỮ CHỨC NĂNG TAP >>>
  SelectableText _buildTappableText(String text, {TextStyle? style}) {
    final defaultStyle = DefaultTextStyle.of(context).style.merge(style);
    final wordRegex = RegExp(r"([a-zA-Z'’]+)"); // Cải thiện regex để bắt cả dấu nháy đơn
    List<TextSpan> textSpans = [];
    int lastMatchEnd = 0;

    wordRegex.allMatches(text).forEach((match) {
      if (match.start > lastMatchEnd) {
        textSpans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: defaultStyle));
      }
      final String word = match.group(0)!;
      textSpans.add(
        TextSpan(
          text: word,
          style: defaultStyle, // Bỏ gạch chân cho giao diện sạch sẽ hơn
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              FocusScope.of(context).unfocus();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DictionaryResultScreen(
                    word: word,
                    folders: widget.folders,
                  ),
                ),
              );
            },
        ),
      );
      lastMatchEnd = match.end;
    });

    if (lastMatchEnd < text.length) {
      textSpans.add(TextSpan(text: text.substring(lastMatchEnd), style: defaultStyle));
    }

    return SelectableText.rich(
      TextSpan(children: textSpans),
      textAlign: TextAlign.justify,
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

  Future<void> _showSaveVocabDialog(DictionaryEntry entry) async {
    if (widget.folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần tạo thư mục trước khi lưu từ!'), backgroundColor: Colors.orangeAccent),
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    Folder? selectedFolder = widget.folders.first;

    final List<String> allPartsOfSpeech = entry.meanings.map((m) => m.partOfSpeech).toSet().toList();
    final List<String> allDefinitions = entry.meanings.expand((meaning) => meaning.definitions.map((def) => def.definition)).toList();

    final meaningController = TextEditingController();
    final partOfSpeechController = TextEditingController();

    String? selectedPartOfSpeech = allPartsOfSpeech.isNotEmpty ? allPartsOfSpeech.first : null;
    meaningController.text = allDefinitions.isNotEmpty ? allDefinitions.first : '';

    bool _showOptions = false;
    String? _selectedImageBase64;
    bool _isSaving = false;
    Alignment _imageAlignment = Alignment.center;

    void disposeResources() {
      meaningController.dispose();
      partOfSpeechController.dispose();
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
            title: Text('Lưu từ "${entry.word}"', style: const TextStyle(color: primaryPink, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
            actionsPadding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 480,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<Folder>(
                        value: selectedFolder, isExpanded: true,
                        decoration: InputDecoration(labelText: 'Chọn thư mục', prefixIcon: const Icon(Icons.folder_open_outlined, color: primaryPink), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        items: widget.folders.map((f) => DropdownMenuItem<Folder>(value: f, child: Text(f.name, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setDialogState(() => selectedFolder = val), validator: (value) => value == null ? 'Vui lòng chọn thư mục' : null,
                      ),
                      const SizedBox(height: 16),
                      if (allPartsOfSpeech.isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          value: selectedPartOfSpeech,
                          decoration: InputDecoration(labelText: 'Loại từ', prefixIcon: const Icon(Icons.category_outlined, color: primaryPink), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: allPartsOfSpeech.map((pos) => DropdownMenuItem<String>(value: pos, child: Text(pos))).toList(),
                          onChanged: (val) => setDialogState(() => selectedPartOfSpeech = val),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: partOfSpeechController,
                          decoration: InputDecoration(labelText: 'Loại từ (tùy chọn)', hintText: 'ví dụ: noun, verb...', prefixIcon: const Icon(Icons.category_outlined, color: primaryPink), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: meaningController,
                            decoration: InputDecoration(
                              labelText: 'Nghĩa của từ (có thể sửa)',
                              prefixIcon: const Icon(Icons.translate, color: primaryPink),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              suffixIcon: IconButton(
                                icon: Icon(_showOptions ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.grey),
                                onPressed: () {
                                  if (allDefinitions.isNotEmpty) {
                                    setDialogState(() => _showOptions = !_showOptions);
                                  }
                                },
                              ),
                            ),
                          ),
                          Visibility(
                            visible: _showOptions,
                            child: Material(
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                  side: BorderSide(color: Colors.grey.shade300)
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 150),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero, shrinkWrap: true,
                                  itemCount: allDefinitions.length,
                                  itemBuilder: (context, index) {
                                    final option = allDefinitions[index];
                                    return ListTile(
                                      title: Text(option, overflow: TextOverflow.ellipsis, maxLines: 2),
                                      onTap: () {
                                        setDialogState(() {
                                          meaningController.text = option;
                                          _showOptions = false;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text("Ảnh minh họa (tùy chọn):", style: TextStyle(fontWeight: FontWeight.bold, color: darkTextColor)),
                      const SizedBox(height: 8),
                      DraggableImageEditor(
                        imageBase64: _selectedImageBase64,
                        onAlignmentChanged: (newAlignment) => _imageAlignment = newAlignment,
                      ),
                      Center(
                        child: TextButton.icon(
                          onPressed: () async {
                            final base64String = await ImageService.pickAndEncodeImage();
                            if (base64String != null) {
                              setDialogState(() => _selectedImageBase64 = base64String);
                            }
                          },
                          icon: const Icon(Icons.photo_library_outlined, color: primaryPink),
                          label: const Text('Chọn ảnh từ thiết bị', style: TextStyle(color: primaryPink)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: _isSaving ? null : () {
                disposeResources();
                Navigator.pop(dialogContext);
              }, child: const Text('Hủy')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: primaryPink, foregroundColor: Colors.white),
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: const Text('Lưu'),
                onPressed: _isSaving ? null : () async {
                  if (meaningController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nghĩa của từ không được để trống!'), backgroundColor: Colors.redAccent));
                    return;
                  }
                  if (formKey.currentState!.validate()) {
                    setDialogState(() => _isSaving = true);
                    try {
                      await AuthService.createVocabulary(
                        entry: entry,
                        folderId: selectedFolder!.id,
                        userDefinedMeaning: meaningController.text.trim(),
                        userDefinedPartOfSpeech: allPartsOfSpeech.isNotEmpty ? selectedPartOfSpeech : (partOfSpeechController.text.trim().isEmpty ? null : partOfSpeechController.text.trim()),
                        userImageBase64: _selectedImageBase64,
                        imageAlignmentX: _imageAlignment.x,
                        imageAlignmentY: _imageAlignment.y,
                      );
                      if (mounted) {
                        disposeResources();
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu từ vựng thành công!'), backgroundColor: Colors.green));
                        Navigator.of(context).pop(true);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
                      }
                    } finally {
                      if (mounted && Navigator.of(dialogContext).canPop()) {
                        setDialogState(() => _isSaving = false);
                      }
                    }
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildMeaningWidget(Meaning meaning) {
    Widget buildSectionHeader(String title, IconData icon, Color color) {
      return Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: accentPink.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(meaning.partOfSpeech, style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: primaryPink, fontSize: 18)),
          ),
          buildSectionHeader('Định nghĩa', Icons.book_outlined, primaryPink),
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
                      Text('$index. ', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkTextColor)),
                      Expanded(child: _buildTappableText(def.definition, style: const TextStyle(fontSize: 16, height: 1.4))),
                    ],
                  ),
                  if (def.example != null && def.example!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0, top: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vd: ', style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey.shade700)),
                          Expanded(child: _buildTappableText('"${def.example!}"', style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey.shade700))),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          if (meaning.synonyms.isNotEmpty) ...[
            buildSectionHeader('Từ đồng nghĩa', Icons.swap_horiz_rounded, Colors.green.shade700),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Wrap(
                spacing: 8.0, runSpacing: 4.0,
                children: meaning.synonyms.map((syn) => GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DictionaryResultScreen(word: syn, folders: widget.folders))),
                  child: Chip(label: Text(syn), backgroundColor: Colors.green.withOpacity(0.15), side: BorderSide.none, labelStyle: TextStyle(color: Colors.green.shade800)),
                )).toList(),
              ),
            ),
          ],
          if (meaning.antonyms.isNotEmpty) ...[
            buildSectionHeader('Từ trái nghĩa', Icons.compare_arrows_rounded, Colors.red.shade700),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Wrap(
                spacing: 8.0, runSpacing: 4.0,
                children: meaning.antonyms.map((ant) => GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DictionaryResultScreen(word: ant, folders: widget.folders))),
                  child: Chip(label: Text(ant), backgroundColor: Colors.red.withOpacity(0.1), side: BorderSide.none, labelStyle: TextStyle(color: Colors.red.shade800)),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundPink,
      appBar: AppBar(
        title: Text('Kết quả: "${widget.word}"', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      // <<< THÊM MỚI: FLOATING ACTION BUTTON >>>
      floatingActionButton: FloatingActionButton(
        onPressed: _showPasteAndTranslateDialog,
        backgroundColor: primaryPink,
        tooltip: 'Dịch nhanh',
        child: const Icon(Icons.translate, color: Colors.white),
      ),
      body: FutureBuilder<List<DictionaryEntry>>(
        future: _lookupFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryPink));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            final customEntry = DictionaryEntry(word: widget.word, meanings: [], phonetic: null, audioUrl: null);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text('Không tìm thấy từ "${widget.word}" trong từ điển.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkTextColor)),
                    const SizedBox(height: 8),
                    const Text('Bạn có muốn tự định nghĩa và lưu từ này vào sổ tay của mình không?', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showSaveVocabDialog(customEntry),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Tự định nghĩa và Lưu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          final entries = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                elevation: 4.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: Text(entry.word, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: primaryPink))),
                          if (entry.phonetic != null) Text(entry.phonetic!, style: const TextStyle(color: Colors.grey, fontSize: 18)),
                          if (entry.audioUrl != null && entry.audioUrl!.isNotEmpty) IconButton(icon: const Icon(Icons.volume_up, color: primaryPink, size: 30), onPressed: () => _playAudio(entry.audioUrl)),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1, color: lightPink),
                      ...entry.meanings.map((meaning) => _buildMeaningWidget(meaning)),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton.icon(
                          onPressed: () => _showSaveVocabDialog(entry),
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: const Text('Lưu từ này'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPink, foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
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
  Future<String>? _translationFuture;
  static const Color primaryPink = Color(0xFFE91E63);

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _translate() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _translationFuture = AuthService.translateWord(_textController.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Row(
        children: [
          Icon(Icons.translate, color: primaryPink),
          SizedBox(width: 10),
          Text('Dịch nhanh'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              maxLines: 5, minLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Dán hoặc nhập văn bản cần dịch...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: 'Dán từ clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data != null) {
                      _textController.text = data.text ?? '';
                      if (_textController.text.isNotEmpty) _translate();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_translationFuture != null)
              FutureBuilder<String>(
                future: _translationFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryPink));
                  }
                  if (snapshot.hasError) {
                    return const Text('Đã có lỗi xảy ra.', style: TextStyle(color: Colors.red));
                  }
                  if (snapshot.hasData) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Text(snapshot.data!, style: TextStyle(fontSize: 16, color: Colors.blue.shade900, fontWeight: FontWeight.w500)),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
        ElevatedButton(
          onPressed: _translate,
          style: ElevatedButton.styleFrom(backgroundColor: primaryPink, foregroundColor: Colors.white),
          child: const Text('Dịch'),
        ),
      ],
    );
  }
}