import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
import '../../Folders/view/folder_selection_dialog.dart';

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

  Future<void> _moveVocabularies({int? singleId}) async {
    final ids =
        singleId != null ? [singleId] : _viewModel.selectedVocabIds.toList();
    if (ids.isEmpty) return;

    final targetFolderId = await showDialog<int>(
      context: context,
      builder:
          (context) => FolderSelectionDialog(currentFolderId: widget.folderId),
    );

    if (targetFolderId != null && mounted) {
      if (singleId != null) {
        // For individual move, we need to temporarily select it
        _viewModel.toggleSelection(singleId);
      }

      final success = await _viewModel.moveVocabularies(targetFolderId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã chuyển từ vựng thành công!')),
        );
      }
    }
  }

  Future<void> _showImportExcelDialog() async {
    // 1. Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final filePath = file.path;

    if (filePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể đọc file. Hãy thử lại.')),
        );
      }
      return;
    }

    // 2. Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const CustomLoadingWidget(color: primaryPink, size: 50),
              const SizedBox(height: 20),
              Text(
                'Đang import "${file.name}"...',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vui lòng đợi',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );

    // 3. Call API
    final importResult = await _viewModel.importFromExcel(filePath);

    // 4. Close loading dialog
    if (mounted) Navigator.of(context).pop();

    // 5. Show result dialog
    if (!mounted) return;
    final totalRows = importResult['totalRows'] ?? 0;
    final successCount = importResult['successCount'] ?? 0;
    final skippedCount = importResult['skippedCount'] ?? 0;
    final errors = (importResult['errors'] as List<dynamic>?)?.cast<String>() ?? [];
    final hasSuccess = successCount > 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              hasSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: hasSuccess ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              hasSuccess ? 'Import thành công!' : 'Import thất bại',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stats row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasSuccess
                    ? Colors.green.withOpacity(0.08)
                    : Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Tổng', totalRows, Colors.blue),
                  _buildStatColumn('Thành công', successCount, Colors.green),
                  _buildStatColumn('Bỏ qua', skippedCount, Colors.orange),
                ],
              ),
            ),
            // Error details
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '⚠️ Chi tiết (${errors.length} thông báo):',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: errors.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $e',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
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
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        hintStyle: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.5),
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: primaryPink,
                        ),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color:
                                        Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                    setState(() {});
                                  },
                                )
                                : null,
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
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
                          vertical: 14,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                if (!_viewModel.isSelectionMode &&
                    _searchController.text.isEmpty)
                  _buildStudyBanner(),
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
            icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
            tooltip: 'Import Excel',
            onPressed: _showImportExcelDialog,
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
          IconButton(
            icon: const Icon(Icons.drive_file_move, color: Colors.white),
            onPressed:
                _viewModel.selectedVocabIds.isEmpty
                    ? null
                    : () => _moveVocabularies(),
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
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
            if (!_viewModel.isSelectionMode &&
                _viewModel.totalVocabulariesCount > 0)
              Text(
                '${_viewModel.totalVocabulariesCount} từ vựng',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
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

  Widget _buildStudyBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReady = _viewModel.totalVocabulariesCount > 0;
    final vocabCount = _viewModel.totalVocabulariesCount;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                isReady
                    ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => StudyModeSelectionView(
                                folderId: widget.folderId,
                                folderName: widget.folderName,
                                vocabularyCount: vocabCount,
                              ),
                        ),
                      );
                    }
                    : null,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isReady ? 1.0 : 0.5,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        isDark
                            ? [const Color(0xFF4A1942), const Color(0xFF2D1B3D)]
                            : [
                              const Color(0xFFFF80AB),
                              const Color(0xFFE91E63),
                            ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPink.withOpacity(isDark ? 0.3 : 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 30,
                      bottom: -15,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Content
                    Row(
                      children: [
                        // Left side - icon + info
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isReady
                                    ? '📚 $vocabCount từ vựng sẵn sàng'
                                    : '⏳ Đang tải từ vựng...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Luyện tập ngay!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right side - arrow
                        // Container(
                        //   padding: const EdgeInsets.all(10),
                        //   decoration: BoxDecoration(
                        //     color: Colors.white.withOpacity(0.2),
                        //     shape: BoxShape.circle,
                        //   ),
                        //   child: const Icon(
                        //     Icons.arrow_forward_rounded,
                        //     color: Colors.white,
                        //     size: 22,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverList() {
    if (_viewModel.isBusy && _viewModel.vocabularies.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CustomLoadingWidget(color: primaryPink, size: 60)),
      );
    }
    if (_viewModel.vocabularies.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryPink.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchController.text.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.auto_stories_rounded,
                  size: 64,
                  color: primaryPink.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Không tìm thấy từ vựng'
                    : 'Chưa có từ vựng nào',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isNotEmpty
                    ? 'Thử tìm với từ khóa khác'
                    : 'Hãy thêm từ vựng vào thư mục này',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstLetter =
        vocab.word.isNotEmpty ? vocab.word[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            isSelected
                ? primaryPink.withOpacity(isDark ? 0.15 : 0.05)
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border:
            isSelected
                ? Border.all(color: primaryPink, width: 2)
                : Border.all(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.withOpacity(0.08),
                ),
        boxShadow: [
          BoxShadow(
            color:
                isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
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
                        child: VocabularyDetailView(
                          vocabulary: vocab,
                          folderId: widget.folderId,
                        ),
                      ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Selection checkbox or letter avatar
                if (_viewModel.isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected ? primaryPink : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              isSelected
                                  ? primaryPink
                                  : Colors.grey.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                              : null,
                    ),
                  )
                else
                  // Letter avatar
                  Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryPink.withOpacity(isDark ? 0.3 : 0.15),
                          primaryPink.withOpacity(isDark ? 0.15 : 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: TextStyle(
                          color:
                              isDark
                                  ? primaryPink.withOpacity(0.9)
                                  : primaryPink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                // Word info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              vocab.word,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (vocab.userDefinedPartOfSpeech != null &&
                              vocab.userDefinedPartOfSpeech!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryPink.withOpacity(
                                  isDark ? 0.2 : 0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                vocab.userDefinedPartOfSpeech!,
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? primaryPink.withOpacity(0.9)
                                          : primaryPink,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (vocab.phoneticText != null &&
                          vocab.phoneticText!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          vocab.phoneticText!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodySmall?.color?.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        vocab.userDefinedMeaning ?? 'Chưa có định nghĩa',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: primaryPink.withOpacity(isDark ? 0.15 : 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.volume_up_rounded, size: 22),
                        color: primaryPink,
                        onPressed: () => _speakVocabulary(vocab),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    if (!_viewModel.isSelectionMode) ...[
                      const SizedBox(height: 4),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.5),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 36,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (v) {
                          if (v == 'edit') _showEditDialog(vocab);
                          if (v == 'delete') _showDeleteDialog(vocab.id);
                          if (v == 'move')
                            _moveVocabularies(singleId: vocab.id);
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      size: 20,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Sửa'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'move',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.drive_file_move_rounded,
                                      size: 20,
                                      color:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Di chuyển'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_rounded,
                                      size: 20,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 12),
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
