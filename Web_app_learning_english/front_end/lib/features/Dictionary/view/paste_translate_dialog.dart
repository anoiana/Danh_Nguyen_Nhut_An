import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../service/dictionary_service.dart';
import '../../../core/widgets/custom_loading_widget.dart';

class PasteTranslateDialog extends StatefulWidget {
  const PasteTranslateDialog({super.key});

  @override
  State<PasteTranslateDialog> createState() => _PasteTranslateDialogState();
}

class _PasteTranslateDialogState extends State<PasteTranslateDialog> {
  final TextEditingController _textController = TextEditingController();
  Future<String>? _translationFuture;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _translate() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _translationFuture = DictionaryService.translateWord(
        _textController.text.trim(),
      );
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      _textController.text = data.text ?? '';
      if (_textController.text.isNotEmpty) _translate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Row(
        children: [
          Icon(Icons.translate, color: Theme.of(context).primaryColor),
          const SizedBox(width: 10),
          const Text('Dịch nhanh'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              minLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Dán hoặc nhập văn bản cần dịch...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  tooltip: 'Dán từ clipboard',
                  onPressed: _pasteFromClipboard,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_translationFuture != null)
              FutureBuilder<String>(
                future: _translationFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CustomLoadingWidget(
                        color: Theme.of(context).primaryColor,
                        size: 60,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Đã có lỗi xảy ra.',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  if (snapshot.hasData) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        snapshot.data!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Dịch'),
        ),
      ],
    );
  }
}
