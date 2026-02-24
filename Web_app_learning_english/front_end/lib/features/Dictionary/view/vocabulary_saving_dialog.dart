import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/dictionary_entry.dart';
import '../../Folders/model/folder.dart';
import '../view_model/dictionary_view_model.dart';
import '../../../core/widgets/draggable_image_editor.dart';
import '../../../api/image_upload_service.dart';

class VocabularySavingDialog extends StatefulWidget {
  final DictionaryEntry entry;
  final List<Folder> folders;

  const VocabularySavingDialog({
    super.key,
    required this.entry,
    required this.folders,
  });

  @override
  State<VocabularySavingDialog> createState() => _VocabularySavingDialogState();
}

class _VocabularySavingDialogState extends State<VocabularySavingDialog> {
  final _formKey = GlobalKey<FormState>();
  late Folder? _selectedFolder;
  late TextEditingController _meaningController;
  late TextEditingController _partOfSpeechController;

  String? _selectedPartOfSpeech;
  bool _showOptions = false;
  String? _selectedImageBase64;
  bool _isSaving = false;
  Alignment _imageAlignment = Alignment.center;

  // Colors are now derived from Theme.of(context)

  List<String> get _allPartsOfSpeech =>
      widget.entry.meanings.map((m) => m.partOfSpeech).toSet().toList();
  List<String> get _allDefinitions =>
      widget.entry.meanings
          .expand((meaning) => meaning.definitions.map((def) => def.definition))
          .toList();

  @override
  void initState() {
    super.initState();
    _selectedFolder = widget.folders.isNotEmpty ? widget.folders.first : null;

    _selectedPartOfSpeech =
        _allPartsOfSpeech.isNotEmpty ? _allPartsOfSpeech.first : null;

    _meaningController = TextEditingController(
      text: _allDefinitions.isNotEmpty ? _allDefinitions.first : '',
    );
    _partOfSpeechController = TextEditingController();
  }

  @override
  void dispose() {
    _meaningController.dispose();
    _partOfSpeechController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_meaningController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nghĩa của từ không được để trống!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final scaffoldMessenger = ScaffoldMessenger.of(context);

      final viewModel = context.read<DictionaryViewModel>();

      final success = await viewModel.createVocabulary(
        entry: widget.entry,
        folderId: _selectedFolder!.id,
        userDefinedMeaning: _meaningController.text.trim(),
        userDefinedPartOfSpeech:
            _allPartsOfSpeech.isNotEmpty
                ? _selectedPartOfSpeech
                : (_partOfSpeechController.text.trim().isEmpty
                    ? null
                    : _partOfSpeechController.text.trim()),
        userImageBase64: _selectedImageBase64,
        imageAlignmentX: _imageAlignment.x,
        imageAlignmentY: _imageAlignment.y,
      );

      if (success) {
        if (mounted)
          Navigator.pop(context, true); // Close dialog with success result
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Đã lưu từ vựng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Lỗi: ${viewModel.errorMessage}')),
          );
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      title: Text(
        'Lưu từ "${widget.entry.word}"',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<Folder>(
                  value: _selectedFolder,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Chọn thư mục',
                    prefixIcon: Icon(
                      Icons.folder_open_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items:
                      widget.folders
                          .map(
                            (f) => DropdownMenuItem<Folder>(
                              value: f,
                              child: Text(
                                f.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => setState(() => _selectedFolder = val),
                  validator:
                      (value) => value == null ? 'Vui lòng chọn thư mục' : null,
                ),
                const SizedBox(height: 16),
                if (_allPartsOfSpeech.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedPartOfSpeech,
                    decoration: InputDecoration(
                      labelText: 'Loại từ',
                      prefixIcon: Icon(
                        Icons.category_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items:
                        _allPartsOfSpeech
                            .map(
                              (pos) => DropdownMenuItem<String>(
                                value: pos,
                                child: Text(pos),
                              ),
                            )
                            .toList(),
                    onChanged:
                        (val) => setState(() => _selectedPartOfSpeech = val),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _partOfSpeechController,
                    decoration: InputDecoration(
                      labelText: 'Loại từ (tùy chọn)',
                      hintText: 'ví dụ: noun, verb...',
                      prefixIcon: Icon(
                        Icons.category_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _meaningController,
                      decoration: InputDecoration(
                        labelText: 'Nghĩa của từ (có thể sửa)',
                        prefixIcon: Icon(
                          Icons.translate,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showOptions
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            if (_allDefinitions.isNotEmpty) {
                              setState(() => _showOptions = !_showOptions);
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
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: _allDefinitions.length,
                            itemBuilder: (context, index) {
                              final option = _allDefinitions[index];
                              return ListTile(
                                title: Text(
                                  option,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                                onTap: () {
                                  setState(() {
                                    _meaningController.text = option;
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
                Text(
                  "Ảnh minh họa (tùy chọn):",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                DraggableImageEditor(
                  imageBase64: _selectedImageBase64,
                  onAlignmentChanged:
                      (newAlignment) => _imageAlignment = newAlignment,
                ),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      final base64String =
                          await ImageUploadService.pickAndEncodeImage();
                      if (base64String != null) {
                        setState(() => _selectedImageBase64 = base64String);
                      }
                    },
                    icon: Icon(
                      Icons.photo_library_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      'Chọn ảnh từ thiết bị',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          icon:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Icon(Icons.save),
          label: const Text('Lưu'),
          onPressed: _isSaving ? null : _handleSave,
        ),
      ],
    );
  }
}
