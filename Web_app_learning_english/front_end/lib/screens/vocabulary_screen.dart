import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/api/auth_service.dart';
import 'package:untitled/api/image_upload_service.dart';
import 'package:untitled/api/tts_service.dart';
import 'package:untitled/screens/game_selection_screen.dart';
import 'package:untitled/screens/vocabulary_detail_screen.dart';
import 'package:untitled/widgets/draggable_image_editor.dart';
import 'homescreen.dart';

class VocabularyScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  const VocabularyScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  // === STATE CHÍNH ===
  List<Vocabulary> _vocabularies = [];
  bool _isLoading = true;
  String? _error;
  bool _hasChanges = false;

  // === CÁC DỊCH VỤ ===
  final TextToSpeechService _ttsService = TextToSpeechService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // === STATE CHO PHÂN TRANG VÀ TÌM KIẾM ===
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // === STATE CHO CHẾ ĐỘ CHỌN ===
  bool _isSelectionMode = false;
  final Set<int> _selectedVocabIds = {};

  @override
  void initState() {
    super.initState();
    _resetAndFetchVocabularies();
    _ttsService.init();

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _resetAndFetchVocabularies();
      });
    });

    _scrollController.addListener(() {
      // Tải thêm khi cuộn gần đến cuối danh sách
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchMoreVocabularies();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _ttsService.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- CÁC HÀM TẢI DỮ LIỆU ---

  Future<void> _resetAndFetchVocabularies() async {
    setState(() {
      _isLoading = true;
      _vocabularies = [];
      _currentPage = 0;
      _hasMore = true;
      _error = null;
      _selectedVocabIds.clear(); // Xóa lựa chọn khi tải lại
    });
    try {
      final vocabPage = await AuthService.getVocabulariesByFolder(
        widget.folderId,
        page: _currentPage,
        search: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _vocabularies = vocabPage.content;
          _hasMore = !vocabPage.isLast;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreVocabularies() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    _currentPage++;
    try {
      final vocabPage = await AuthService.getVocabulariesByFolder(
        widget.folderId,
        page: _currentPage,
        search: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _vocabularies.addAll(vocabPage.content);
          _hasMore = !vocabPage.isLast;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // --- CÁC HÀM QUẢN LÝ CHẾ ĐỘ CHỌN ---

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedVocabIds.clear();
    });
  }

  void _onVocabSelected(bool? isSelected, int vocabId) {
    setState(() {
      if (isSelected == true) {
        _selectedVocabIds.add(vocabId);
      } else {
        _selectedVocabIds.remove(vocabId);
      }
    });
  }

  void _selectAll() {
    if (_vocabularies.isEmpty) return;
    setState(() {
      // So sánh với danh sách từ vựng hiện tại trên màn hình
      if (_selectedVocabIds.length < _vocabularies.length) {
        _selectedVocabIds.addAll(_vocabularies.map((v) => v.id));
      } else {
        _selectedVocabIds.clear();
      }
    });
  }

  // --- CÁC DIALOG VÀ HÀNH ĐỘNG ---

  Future<void> _showBulkDeleteDialog() async {
    if (_selectedVocabIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 10), Text('Xác nhận xóa')]),
        content: Text('Bạn có chắc muốn xóa vĩnh viễn ${_selectedVocabIds.length} từ đã chọn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Xóa'),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await AuthService.deleteVocabularies(_selectedVocabIds.toList());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa thành công!')));
                  _hasChanges = true;
                  _toggleSelectionMode();
                  _resetAndFetchVocabularies();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e')));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showMoveVocabDialog() async {
    if (_selectedVocabIds.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: HomeScreen.primaryPink)));

    try {
      // Gọi hàm lấy folder với phân trang (chỉ tải trang đầu tiên)
      final folderPage = await AuthService.getFoldersByUser(userId);
      final allFolders = folderPage.content;
      final otherFolders = allFolders.where((f) => f.id != widget.folderId).toList();

      if (mounted) Navigator.pop(context);

      if (otherFolders.isEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(children: [Icon(Icons.info_outline, color: Colors.blue), SizedBox(width: 10), Text('Thông báo')]),
              content: const Text('Bạn chưa có thư mục nào khác để chuyển các từ này đến.'),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Đã hiểu'))],
            ),
          );
        }
        return;
      }

      int? selectedFolderId;
      bool isMoving = false;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(children: [const Icon(Icons.drive_file_move_outline, color: HomeScreen.primaryPink), const SizedBox(width: 10), Expanded(child: Text('Chuyển ${_selectedVocabIds.length} từ'))]),
            content: DropdownButtonFormField<int>(
              decoration: InputDecoration(labelText: 'Chọn thư mục đích', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.folder_copy_outlined)),
              hint: const Text('Chuyển đến...'),
              value: selectedFolderId,
              isExpanded: true,
              items: otherFolders.map((folder) => DropdownMenuItem<int>(value: folder.id, child: Text(folder.name, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: isMoving ? null : (value) => setDialogState(() => selectedFolderId = value),
              validator: (value) => value == null ? 'Vui lòng chọn thư mục' : null,
            ),
            actions: <Widget>[
              TextButton(onPressed: isMoving ? null : () => Navigator.pop(dialogContext), child: const Text('Hủy')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: HomeScreen.primaryPink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                icon: isMoving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded),
                label: const Text('Chuyển'),
                onPressed: selectedFolderId == null || isMoving ? null : () async {
                  setDialogState(() => isMoving = true);
                  try {
                    await AuthService.moveVocabularies(_selectedVocabIds.toList(), selectedFolderId!);
                    if (mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chuyển thành công!')));
                      _hasChanges = true;
                      _toggleSelectionMode();
                      _resetAndFetchVocabularies();
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi chuyển: $e')));
                  } finally {
                    if (mounted) setDialogState(() => isMoving = false);
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tải thư mục: $e')));
      }
    }
  }

  Future<void> _showEditVocabDialog(Vocabulary vocab) async {
    final formKey = GlobalKey<FormState>();
    final meaningController = TextEditingController(text: vocab.userDefinedMeaning);

    // --- START: LOGIC MỚI, XỬ LÝ CẢ 2 TRƯỜNG HỢP ---
    // Controller cho ô nhập loại từ (dùng khi không có danh sách sẵn)
    final partOfSpeechController = TextEditingController(text: vocab.userDefinedPartOfSpeech ?? '');

    // Lấy danh sách loại từ có sẵn từ dữ liệu gốc (nếu có)
    final List<String> allPartsOfSpeech = (vocab.meanings ?? [])
        .map((m) => m.partOfSpeech)
        .toSet()
        .toList();

    // State để lưu loại từ được chọn từ dropdown
    String? selectedPartOfSpeech;

    // Thiết lập giá trị ban đầu cho dropdown (nếu có)
    if (allPartsOfSpeech.isNotEmpty) {
      // Ưu tiên hiển thị loại từ mà người dùng đã lưu trước đó
      if (vocab.userDefinedPartOfSpeech != null && allPartsOfSpeech.contains(vocab.userDefinedPartOfSpeech)) {
        selectedPartOfSpeech = vocab.userDefinedPartOfSpeech;
      } else {
        // Nếu không, chọn loại từ đầu tiên trong danh sách
        selectedPartOfSpeech = allPartsOfSpeech.first;
      }
    }
    // --- END: LOGIC MỚI ---

    String? newImageBase64;
    bool isSaving = false;
    Alignment imageAlignment = vocab.imageAlignment ?? Alignment.center;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [const Icon(Icons.edit_note, color: HomeScreen.primaryPink), const SizedBox(width: 10), Expanded(child: Text('Sửa từ: "${vocab.word}"', overflow: TextOverflow.ellipsis))]),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Sửa nghĩa (không đổi)
                  TextFormField(
                    controller: meaningController,
                    decoration: const InputDecoration(labelText: 'Nghĩa của bạn', hintText: 'Nhập nghĩa tiếng Việt...', border: OutlineInputBorder()),
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'Nghĩa không được để trống' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. Sửa loại từ (LOGIC HIỂN THỊ CÓ ĐIỀU KIỆN)
                  // Nếu có danh sách loại từ từ API, hiển thị Dropdown
                  if (allPartsOfSpeech.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedPartOfSpeech,
                      decoration: InputDecoration(
                        labelText: 'Loại từ',
                        prefixIcon: const Icon(Icons.category_outlined, color: HomeScreen.primaryPink),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: allPartsOfSpeech.map((pos) {
                        return DropdownMenuItem<String>(value: pos, child: Text(pos));
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() => selectedPartOfSpeech = val);
                      },
                    )
                  // Nếu không, hiển thị ô Text để người dùng tự nhập
                  else
                    TextFormField(
                      controller: partOfSpeechController,
                      decoration: InputDecoration(
                        labelText: 'Loại từ',
                        hintText: 'ví dụ: noun, verb...',
                        prefixIcon: const Icon(Icons.category_outlined, color: HomeScreen.primaryPink),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 3. Sửa ảnh (không đổi)
                  const Text('Ảnh minh họa', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DraggableImageEditor(
                    imageBase64: newImageBase64 ?? vocab.userImageBase64,
                    onAlignmentChanged: (newAlignment) => imageAlignment = newAlignment,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final base64String = await ImageService.pickAndEncodeImage();
                        if (base64String != null) {
                          setDialogState(() {
                            newImageBase64 = base64String;
                            imageAlignment = Alignment.center;
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library_outlined, color: HomeScreen.primaryPink),
                      label: const Text('Thay đổi ảnh', style: TextStyle(color: HomeScreen.primaryPink)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: isSaving ? null : () => Navigator.pop(dialogContext), child: const Text('Hủy')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: HomeScreen.primaryPink, foregroundColor: Colors.white),
              icon: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: const Text('Lưu'),
              onPressed: isSaving ? null : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isSaving = true);
                  try {
                    // CẬP NHẬT LỜI GỌI HÀM, TRUYỀN THAM SỐ MỚI
                    await AuthService.updateVocabulary(
                      vocabularyId: vocab.id,
                      userDefinedMeaning: meaningController.text.trim(),
                      // <-- LOGIC GỬI DỮ LIỆU ĐÚNG ĐẮN -->
                      userDefinedPartOfSpeech: allPartsOfSpeech.isNotEmpty
                          ? selectedPartOfSpeech // Lấy từ dropdown nếu có
                          : (partOfSpeechController.text.trim().isEmpty ? null : partOfSpeechController.text.trim()), // Lấy từ textfield nếu không
                      userImageBase64: newImageBase64 ?? vocab.userImageBase64,
                      imageAlignmentX: imageAlignment.x,
                      imageAlignmentY: imageAlignment.y,
                    );
                    if (mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
                      _hasChanges = true;
                      _resetAndFetchVocabularies();
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  } finally {
                    if (mounted) setDialogState(() => isSaving = false);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteVocabDialog(int vocabId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 10), Text('Xác nhận xóa')]),
        content: const Text('Bạn có chắc muốn xóa từ vựng này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              try {
                await AuthService.deleteVocabulary(vocabId);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa từ vựng.')));
                  _hasChanges = true;
                  _resetAndFetchVocabularies();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // --- CÁC WIDGET BUILD ---

  @override
  Widget build(BuildContext context) {
    final bool hasVocab = _vocabularies.isNotEmpty;
    final bool hasSelection = _selectedVocabIds.isNotEmpty;

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _toggleSelectionMode();
          return false;
        } else {
          Navigator.of(context).pop(_hasChanges);
          return false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isSelectionMode ? '${_selectedVocabIds.length} đã chọn' : 'Thư mục: ${widget.folderName}'),
          backgroundColor: HomeScreen.primaryPink,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.arrow_back),
            tooltip: _isSelectionMode ? 'Hủy' : 'Quay lại',
            onPressed: () {
              if (_isSelectionMode) {
                _toggleSelectionMode();
              } else {
                Navigator.of(context).pop(_hasChanges);
              }
            },
          ),
          actions: [
            if (hasVocab && !_isSelectionMode) IconButton(icon: const Icon(Icons.edit_note), tooltip: 'Chỉnh sửa danh sách', onPressed: _toggleSelectionMode),
            if (_isSelectionMode) ...[
              IconButton(icon: Icon(_selectedVocabIds.length == _vocabularies.length ? Icons.deselect : Icons.select_all), tooltip: 'Chọn/Bỏ chọn tất cả', onPressed: _selectAll),
              IconButton(icon: const Icon(Icons.drive_file_move_outline), tooltip: 'Chuyển thư mục', onPressed: hasSelection ? _showMoveVocabDialog : null),
              IconButton(icon: const Icon(Icons.delete_sweep_outlined), tooltip: 'Xóa mục đã chọn', onPressed: hasSelection ? _showBulkDeleteDialog : null),
            ]
          ],
        ),
        floatingActionButton: _isSelectionMode
            ? null
            : FloatingActionButton.extended(
          onPressed: () {
            if (_vocabularies.length < 4) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cần có ít nhất 4 từ vựng để bắt đầu luyện tập!')));
              return;
            }
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => GameSelectionScreen(folderId: widget.folderId, folderName: widget.folderName, vocabularyCount: _vocabularies.length)));
          },
          label: const Text('Luyện tập'),
          icon: const Icon(Icons.psychology_outlined),
          tooltip: 'Bắt đầu luyện tập',
          backgroundColor: HomeScreen.primaryPink,
          foregroundColor: Colors.white,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: HomeScreen.primaryPink));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.cloud_off, color: Colors.red, size: 80),
            const SizedBox(height: 16),
            const Text('Ôi, có lỗi xảy ra!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 16), textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    if (_vocabularies.isEmpty && _searchController.text.trim().isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.inbox_outlined, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Thư mục này trống trơn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Hãy tra từ điển ở trang chủ và lưu lại để lấp đầy nơi này nhé!', style: TextStyle(fontSize: 15, color: Colors.grey[600]), textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm từ vựng...',
              prefixIcon: const Icon(Icons.search, color: HomeScreen.primaryPink),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: const BorderSide(color: HomeScreen.primaryPink, width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear()) : null,
            ),
          ),
        ),
        Expanded(
          child: _vocabularies.isEmpty
              ? Center(child: Text('Không tìm thấy từ nào khớp.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)))
              : _buildVocabularyList(),
        ),
      ],
    );
  }

  Widget _buildVocabularyList() {
    return RefreshIndicator(
      onRefresh: _resetAndFetchVocabularies,
      color: HomeScreen.primaryPink,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
        itemCount: _vocabularies.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _vocabularies.length) {
            return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: HomeScreen.primaryPink)));
          }
          final vocab = _vocabularies[index];
          final isSelected = _selectedVocabIds.contains(vocab.id);
          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            color: isSelected ? HomeScreen.primaryPink.withOpacity(0.15) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isSelected ? HomeScreen.primaryPink : Colors.transparent, width: 2),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.only(left: _isSelectionMode ? 12 : 16, right: 16, top: 8, bottom: 8),
              leading: _isSelectionMode
                  ? Checkbox(value: isSelected, onChanged: (bool? value) => _onVocabSelected(value, vocab.id), activeColor: HomeScreen.primaryPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))
                  : CircleAvatar(
                backgroundColor: HomeScreen.primaryPink.withOpacity(0.1),
                child: IconButton(
                  icon: const Icon(Icons.volume_up, color: HomeScreen.primaryPink),
                  onPressed: () {
                    if (vocab.audioUrl != null && vocab.audioUrl!.isNotEmpty) {
                      _audioPlayer.play(UrlSource(vocab.audioUrl!));
                    } else {
                      _ttsService.speak(vocab.word);
                    }
                  },
                ),
              ),
              title: Text(vocab.word, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (vocab.phoneticText != null && vocab.phoneticText!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2.0), child: Text(vocab.phoneticText!, style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic))),
                const SizedBox(height: 4),
                Text(vocab.userDefinedMeaning ?? 'Chưa có nghĩa tùy chỉnh', maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
              trailing: _isSelectionMode ? null : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') _showEditVocabDialog(vocab);
                  if (value == 'delete') _showDeleteVocabDialog(vocab.id);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20, color: Colors.blue), SizedBox(width: 10), Text('Sửa nghĩa/ảnh')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 20), SizedBox(width: 10), Text('Xóa', style: TextStyle(color: Colors.red))])),
                ],
              ),
              onTap: () {
                if (_isSelectionMode) {
                  _onVocabSelected(!isSelected, vocab.id);
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => VocabularyDetailScreen(vocabulary: vocab))).then((didChange) {
                    if (didChange == true) {
                      _resetAndFetchVocabularies();
                    }
                  });
                }
              },
              onLongPress: () {
                if (!_isSelectionMode) {
                  _toggleSelectionMode();
                  _onVocabSelected(true, vocab.id);
                }
              },
            ),
          );
        },
      ),
    );
  }
}