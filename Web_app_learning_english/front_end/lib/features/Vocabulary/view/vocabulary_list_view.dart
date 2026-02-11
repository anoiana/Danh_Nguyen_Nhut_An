import 'dart:async';
import 'package:flutter/material.dart';
import '../model/vocabulary.dart';
import '../view_model/vocabulary_view_model.dart';
import '../../Study_Modes/view/study_mode_selection_view.dart';
import '../../../api/image_upload_service.dart';
import '../../../api/tts_service.dart';
import '../../../core/widgets/draggable_image_editor.dart';
import 'package:audioplayers/audioplayers.dart';
import '../view/vocabulary_detail_view.dart';
import '../view_model/vocabulary_detail_view_model.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_loading_widget.dart';

// Reuse colors
const Color primaryPink = Color(0xFFE91E63);

class VocabularyListView extends StatefulWidget {
  final int folderId;
  final String folderName;

  const VocabularyListView({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<VocabularyListView> createState() => _VocabularyListViewState();
}

class _VocabularyListViewState extends State<VocabularyListView> {
  final VocabularyViewModel _viewModel = VocabularyViewModel();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextToSpeechService _ttsService = TextToSpeechService();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _viewModel.init(widget.folderId, widget.folderName);
    _ttsService.init();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_viewModel.isLoadingMore &&
          _viewModel.hasMore) {
        _viewModel.fetchVocabularies(refresh: false);
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _audioPlayer.dispose();
    _ttsService.stop();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _viewModel.setSearchQuery(query);
    });
  }

  void _speakVocabulary(Vocabulary vocab) {
    StringBuffer sb = StringBuffer();
    sb.write(vocab.word);

    if (vocab.userDefinedPartOfSpeech != null &&
        vocab.userDefinedPartOfSpeech!.isNotEmpty) {
      sb.write(". ${vocab.userDefinedPartOfSpeech}");
    }

    _ttsService.speak(sb.toString());
  }

  void _showTtsSettingsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        double currentRate = _ttsService.speechRate;
        return StatefulBuilder(
          builder: (innerContext, setState) {
            return AlertDialog(
              title: const Text('Cài đặt giọng nói'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tốc độ đọc'),
                  Row(
                    children: [
                      const Text('Chậm', style: TextStyle(fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: currentRate,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          label: currentRate.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              currentRate = value;
                            });
                            _ttsService.setSpeechRate(value);
                          },
                        ),
                      ),
                      const Text('Nhanh', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditDialog(Vocabulary vocab) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final formKey = GlobalKey<FormState>();
    final meaningController = TextEditingController(
      text: vocab.userDefinedMeaning,
    );
    final partOfSpeechController = TextEditingController(
      text: vocab.userDefinedPartOfSpeech ?? '',
    );

    String? newImageBase64;
    Alignment imageAlignment = vocab.imageAlignment ?? Alignment.center;
    bool isUpdating = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (innerContext, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Sửa từ: "${vocab.word}"',
                  overflow: TextOverflow.ellipsis,
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: meaningController,
                          decoration: const InputDecoration(
                            labelText: 'Nghĩa',
                            border: OutlineInputBorder(),
                          ),
                          validator:
                              (val) =>
                                  (val == null || val.isEmpty)
                                      ? 'Nhập nghĩa'
                                      : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: partOfSpeechController,
                          decoration: const InputDecoration(
                            labelText: 'Loại từ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DraggableImageEditor(
                          imageBase64: newImageBase64 ?? vocab.userImageBase64,
                          onAlignmentChanged: (align) => imageAlignment = align,
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final base64 =
                                await ImageUploadService.pickAndEncodeImage();
                            if (base64 != null) {
                              setDialogState(() => newImageBase64 = base64);
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Đổi ảnh'),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        isUpdating ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed:
                        isUpdating
                            ? null
                            : () async {
                              if (formKey.currentState!.validate()) {
                                setDialogState(() {
                                  isUpdating = true;
                                });
                                final success = await _viewModel
                                    .updateVocabulary(
                                      id: vocab.id,
                                      meaning: meaningController.text.trim(),
                                      partOfSpeech:
                                          partOfSpeechController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : partOfSpeechController.text
                                                  .trim(),
                                      imageBase64:
                                          newImageBase64 ??
                                          vocab.userImageBase64,
                                      alignX: imageAlignment.x,
                                      alignY: imageAlignment.y,
                                    );
                                if (success && mounted) {
                                  Navigator.pop(dialogContext);
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Cập nhật thành công'),
                                    ),
                                  );
                                } else {
                                  setDialogState(() {
                                    isUpdating = false;
                                  });
                                }
                              }
                            },
                    child:
                        isUpdating
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Lưu'),
                  ),
                ],
              );
            },
          ),
    );
  }

  Future<void> _showDeleteDialog(int id) async {
    bool isDeleting = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Xóa từ vựng?'),
                content: const Text('Bạn có chắc muốn xóa từ này không?'),
                actions: [
                  TextButton(
                    onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed:
                        isDeleting
                            ? null
                            : () async {
                              setDialogState(() {
                                isDeleting = true;
                              });
                              await _viewModel.deleteVocabulary(id);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                    child:
                        isDeleting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text(
                              'Xóa',
                              style: TextStyle(color: Colors.red),
                            ),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.pop(context, _viewModel.hasChanges);
            return false;
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFFCE4EC), // backgroundPink
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm từ vựng...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: primaryPink,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(
                            color: primaryPink.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: primaryPink,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                _buildSliverList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 150.0,
      floating: true,
      pinned: true,
      backgroundColor: primaryPink,
      leading: IconButton(
        icon: Icon(
          _viewModel.isSelectionMode ? Icons.close : Icons.arrow_back,
          color: Colors.white,
        ),
        onPressed: () {
          if (_viewModel.isSelectionMode) {
            _viewModel.toggleSelectionMode();
          } else {
            Navigator.pop(context, _viewModel.hasChanges);
          }
        },
      ),
      actions: [
        if (!_viewModel.isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.school, color: Colors.white),
            tooltip: 'Chế độ học',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => StudyModeSelectionView(
                        folderId: widget.folderId,
                        folderName: widget.folderName,
                        vocabularyCount: _viewModel.totalVocabulariesCount,
                      ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.checklist, color: Colors.white),
            onPressed: _viewModel.toggleSelectionMode,
          ),
        ],
        if (_viewModel.isSelectionMode) ...[
          IconButton(
            icon: const Icon(Icons.select_all, color: Colors.white),
            onPressed: _viewModel.selectAll,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed:
                _viewModel.selectedVocabIds.isEmpty
                    ? null
                    : () {
                      _viewModel.deleteSelectedVocabularies();
                    },
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          _viewModel.isSelectionMode
              ? '${_viewModel.selectedVocabIds.length} đã chọn'
              : widget.folderName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF80AB), Color(0xFFE91E63), Color(0xFFC2185B)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverList() {
    if (_viewModel.isBusy && _viewModel.vocabularies.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_viewModel.vocabularies.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Chưa có từ vựng nào.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == _viewModel.vocabularies.length) {
            return _viewModel.hasMore
                ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CustomLoadingWidget(color: primaryPink, size: 40),
                  ),
                )
                : const SizedBox.shrink();
          }
          final vocab = _viewModel.vocabularies[index];
          final isSelected = _viewModel.selectedVocabIds.contains(vocab.id);

          return _buildPremiumCard(vocab, isSelected);
        }, childCount: _viewModel.vocabularies.length + 1),
      ),
    );
  }

  Widget _buildPremiumCard(Vocabulary vocab, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? primaryPink.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isSelected
                ? Border.all(color: primaryPink, width: 2)
                : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (_viewModel.isSelectionMode) {
              _viewModel.toggleSelection(vocab.id);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChangeNotifierProvider(
                        create: (_) => VocabularyDetailViewModel(),
                        child: VocabularyDetailView(vocabulary: vocab),
                      ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_viewModel.isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: isSelected ? primaryPink : Colors.grey,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vocab.word,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (vocab.phoneticText != null &&
                          vocab.phoneticText!.isNotEmpty)
                        Text(
                          vocab.phoneticText!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        vocab.userDefinedMeaning ?? 'Chưa có định nghĩa',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[800], fontSize: 15),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up_rounded),
                      color: primaryPink,
                      onPressed: () => _speakVocabulary(vocab),
                    ),
                    if (!_viewModel.isSelectionMode)
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                        onSelected: (v) {
                          if (v == 'edit') _showEditDialog(vocab);
                          if (v == 'delete') _showDeleteDialog(vocab.id);
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Sửa'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
