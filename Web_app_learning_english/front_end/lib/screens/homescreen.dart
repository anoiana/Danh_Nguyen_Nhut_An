import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/api/auth_service.dart';
import 'package:untitled/screens/vocabulary_screen.dart';
import 'package:untitled/screens/dictionary_result_screen.dart';
import 'login_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const Color primaryPink = Color(0xFFE91E63);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // === STATE CHÍNH ===
  int? _userId;
  String? _username;
  List<Folder> _folders = [];
  bool _isLoading = true;
  String _error = '';

  // === STATE CHO CÁC CHỨC NĂNG ===
  final _dictionarySearchController = TextEditingController();
  final _folderSearchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  // === STATE ĐỂ QUẢN LÝ UI TÌM KIẾM FOLDER ===
  bool _isSearchingFolders = false;
  final FocusNode _folderSearchFocusNode = FocusNode();

  // === STATE CHO PHÂN TRANG ===
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchFolders();

    _folderSearchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), _resetAndFetchFolders);
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchMoreFolders();
      }
    });
  }

  @override
  void dispose() {
    _dictionarySearchController.dispose();
    _folderSearchController.dispose();
    _scrollController.dispose();
    _folderSearchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- CÁC HÀM LOGIC ---

  Future<void> _loadUserDataAndFetchFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final username = prefs.getString('username');
    if (userId == null || username == null) {
      _logout();
      return;
    }
    setState(() {
      _userId = userId;
      _username = username;
    });
    _resetAndFetchFolders();
  }

  Future<void> _resetAndFetchFolders() async {
    if (_userId == null) return;
    setState(() {
      _isLoading = true;
      _folders = [];
      _currentPage = 0;
      _hasMore = true;
      _error = '';
    });
    try {
      final folderPage = await AuthService.getFoldersByUser(
        _userId!,
        page: _currentPage,
        search: _folderSearchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _folders = folderPage.content;
          _hasMore = !folderPage.isLast;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Lỗi tải thư mục: ${e.toString()}";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreFolders() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    try {
      final folderPage = await AuthService.getFoldersByUser(
        _userId!,
        page: _currentPage,
        search: _folderSearchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _folders.addAll(folderPage.content);
          _hasMore = !folderPage.isLast;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  void _handleDictionarySearch() async {
    final word = _dictionarySearchController.text.trim();
    if (word.isNotEmpty && _userId != null) {
      final folderPage = await AuthService.getFoldersByUser(_userId!, page: 0, size: 100);
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DictionaryResultScreen(word: word, folders: folderPage.content),
        ),
      );
      if (result == true) {
        _resetAndFetchFolders();
      }
    }
  }

  void _toggleFolderSearch() {
    setState(() {
      _isSearchingFolders = !_isSearchingFolders;
      if (!_isSearchingFolders) {
        _folderSearchController.clear();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _folderSearchFocusNode.requestFocus();
        });
      }
    });
  }

  Future<void> _createFolder(String folderName) async {
    try {
      await AuthService.createFolder(folderName, _userId!);
      _resetAndFetchFolders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo thư mục thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
        );
      }
    }
  }

  Future<void> _showCreateFolderDialog() async {
    final folderNameController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [Icon(Icons.create_new_folder, color: HomeScreen.primaryPink), SizedBox(width: 10), Text('Tạo thư mục mới')]),
          content: TextField(controller: folderNameController, decoration: const InputDecoration(hintText: "Nhập tên thư mục", prefixIcon: Icon(Icons.drive_file_rename_outline)), autofocus: true),
          actions: <Widget>[
            TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: HomeScreen.primaryPink, foregroundColor: Colors.white),
              icon: const Icon(Icons.add),
              label: const Text('Tạo'),
              onPressed: () async {
                final folderName = folderNameController.text.trim();
                if (folderName.isNotEmpty && _userId != null) {
                  Navigator.of(context).pop();
                  await _createFolder(folderName);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(int folderId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 10), Text('Xác nhận xóa')]),
          content: const Text('Bạn có chắc chắn muốn xóa thư mục này không? Tất cả từ vựng bên trong cũng sẽ bị xóa vĩnh viễn.'),
          actions: <Widget>[
            TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Xóa'),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await AuthService.deleteFolder(folderId);
                  _resetAndFetchFolders();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa thư mục.')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: ${e.toString()}')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(Folder folder) async {
    final editController = TextEditingController(text: folder.name);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [Icon(Icons.edit_note, color: HomeScreen.primaryPink), SizedBox(width: 10), Text('Sửa tên thư mục')]),
          content: TextField(controller: editController, decoration: const InputDecoration(hintText: "Nhập tên mới", prefixIcon: Icon(Icons.drive_file_rename_outline)), autofocus: true),
          actions: <Widget>[
            TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: HomeScreen.primaryPink, foregroundColor: Colors.white),
              icon: const Icon(Icons.save),
              label: const Text('Lưu'),
              onPressed: () async {
                final newName = editController.text.trim();
                if (newName.isNotEmpty && newName != folder.name) {
                  Navigator.of(context).pop();
                  try {
                    await AuthService.updateFolder(folder.id, newName);
                    _resetAndFetchFolders();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!')));
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }


  // --- WIDGET BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: HomeScreen.primaryPink,
        foregroundColor: Colors.white,
        title: Text('Xin chào, ${_username ?? 'bạn'}!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: 'Đăng xuất')],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateFolderDialog,
        tooltip: 'Tạo thư mục mới',
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('Tạo thư mục'),
        backgroundColor: HomeScreen.primaryPink,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: HomeScreen.primaryPink))
          : _error.isNotEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(_error, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center),
          ]),
        ),
      )
          : RefreshIndicator(
        onRefresh: _resetAndFetchFolders,
        color: HomeScreen.primaryPink,
        child: Column(
          children: [
            // --- Thanh tra từ điển chính ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _dictionarySearchController,
                decoration: InputDecoration(
                  hintText: 'Tra từ điển Anh - Anh',
                  prefixIcon: const Icon(Icons.search, color: HomeScreen.primaryPink),
                  filled: true,
                  fillColor: HomeScreen.primaryPink.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: const BorderSide(color: HomeScreen.primaryPink, width: 2)),
                ),
                onSubmitted: (_) => _handleDictionarySearch(),
              ),
            ),

            // --- Header của danh sách thư mục (có thể chuyển đổi) ---
            _buildFolderHeader(),

            const Divider(height: 1, thickness: 1),

            // --- Danh sách thư mục ---
            Expanded(
              child: _folders.isEmpty && _folderSearchController.text.trim().isEmpty
                  ? Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50.0),
                    child: Column(children: [
                      Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Chưa có thư mục nào.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Nhấn nút "Tạo thư mục" để bắt đầu nhé!', style: TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                    ]),
                  ),
                ),
              )
                  : _folders.isEmpty
                  ? Center(child: Text('Không tìm thấy thư mục nào khớp.', style: TextStyle(color: Colors.grey.shade600)))
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 80, top: 8),
                itemCount: _folders.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _folders.length) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: HomeScreen.primaryPink)));
                  }
                  final folder = _folders[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: CircleAvatar(backgroundColor: HomeScreen.primaryPink.withOpacity(0.1), child: const Icon(Icons.folder_copy_rounded, color: HomeScreen.primaryPink)),
                      title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${folder.vocabularyCount} từ vựng', style: TextStyle(color: Colors.grey[600])),
                      onTap: () async {
                        final result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => VocabularyScreen(folderId: folder.id, folderName: folder.name)));
                        if (result == true) {
                          _resetAndFetchFolders();
                        }
                      },
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') _showEditDialog(folder);
                          else if (value == 'delete') _showDeleteDialog(folder.id);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 10), Text('Sửa tên')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_forever, color: Colors.red, size: 20), SizedBox(width: 10), Text('Xóa', style: TextStyle(color: Colors.red))])),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: _isSearchingFolders
            ? TextField(
          key: const ValueKey('folderSearchField'),
          controller: _folderSearchController,
          focusNode: _folderSearchFocusNode,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm thư mục...',
            prefixIcon: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Đóng tìm kiếm',
              onPressed: _toggleFolderSearch,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
          ),
        )
            : Row(
          key: const ValueKey('folderHeader'),
          children: [
            Icon(Icons.folder_special_rounded, color: HomeScreen.primaryPink.withOpacity(0.8)),
            const SizedBox(width: 8),
            Text('Thư mục của bạn', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Tìm kiếm thư mục',
              onPressed: _toggleFolderSearch,
            ),
          ],
        ),
      ),
    );
  }
}