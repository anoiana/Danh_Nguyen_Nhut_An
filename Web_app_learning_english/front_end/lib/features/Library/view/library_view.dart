import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/speech_rate_bottom_sheet.dart';
import '../../../api/tts_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';

import '../../Authentication/view/login_view.dart';
import '../../Folders/model/folder.dart';
import '../../Folders/view_model/folder_list_view_model.dart';
import '../../Vocabulary/view/vocabulary_list_view.dart';
import '../../Dictionary/view/dictionary_result_view.dart';
import '../../Dictionary/view_model/dictionary_view_model.dart';

// Theme Colors
const Color primaryPink = Color(0xFFE91E63);
const Color backgroundPink = Color(0xFFFCE4EC);

class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FolderListViewModel _viewModel = FolderListViewModel();
  final _folderSearchController = TextEditingController();
  final _dictionarySearchController = TextEditingController();
  final _folderSearchFocusNode = FocusNode();
  final _scrollController = ScrollController();

  // Search State Local
  bool _isSearchingFolders = false;

  // Global Loading State
  bool _isGlobalLoading = false;

  @override
  void initState() {
    super.initState();
    _viewModel.loadUserDataAndFetchFolders();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_viewModel.isLoadingMore &&
          _viewModel.hasMore) {
        _viewModel.fetchMoreFolders();
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _folderSearchController.dispose();
    _dictionarySearchController.dispose();
    _scrollController.dispose();
    _folderSearchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginView(),
        ), // Navigate to new LoginView
        (Route<dynamic> route) => false,
      );
    }
  }

  void _handleDictionarySearch() async {
    final word = _dictionarySearchController.text.trim();
    if (word.isNotEmpty) {
      // We pass current folders to dictionary so user can save words to them
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ChangeNotifierProvider(
                create: (_) => DictionaryViewModel(),
                child: DictionaryResultView(
                  word: word,
                  folders: _viewModel.folders,
                ),
              ),
        ),
      );
      if (result == true) {
        _viewModel.loadUserDataAndFetchFolders(); // Refresh if folder updated
      }
    }
  }

  void _toggleFolderSearch() {
    setState(() {
      _isSearchingFolders = !_isSearchingFolders;
      if (!_isSearchingFolders) {
        _folderSearchController.clear();
        _viewModel.onSearchChanged('');
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _folderSearchFocusNode.requestFocus();
        });
      }
    });
  }

  // Dialogs
  Future<void> _showCreateFolderDialog() async {
    final folderNameController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.create_new_folder, color: primaryPink),
              SizedBox(width: 10),
              Text('Tạo thư mục mới'),
            ],
          ),
          content: TextField(
            controller: folderNameController,
            decoration: const InputDecoration(
              hintText: "Nhập tên thư mục",
              prefixIcon: Icon(Icons.drive_file_rename_outline),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Tạo'),
              onPressed: () async {
                final folderName = folderNameController.text.trim();
                if (folderName.isNotEmpty) {
                  Navigator.of(context).pop();
                  setState(() => _isGlobalLoading = true);
                  try {
                    bool success = await _viewModel.createFolder(folderName);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tạo thư mục thành công!'),
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isGlobalLoading = false);
                  }
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
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.edit_note, color: primaryPink),
              SizedBox(width: 10),
              Text('Sửa tên thư mục'),
            ],
          ),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              hintText: "Nhập tên mới",
              prefixIcon: Icon(Icons.drive_file_rename_outline),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save),
              label: const Text('Lưu'),
              onPressed: () async {
                final newName = editController.text.trim();
                if (newName.isNotEmpty && newName != folder.name) {
                  Navigator.of(context).pop();
                  setState(() => _isGlobalLoading = true);
                  try {
                    bool success = await _viewModel.updateFolder(
                      folder.id,
                      newName,
                    );
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật thành công!')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isGlobalLoading = false);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(int folderId) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Xác nhận xóa'),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn xóa thư mục này không? Tất cả từ vựng bên trong cũng sẽ bị xóa vĩnh viễn.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Xóa'),
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => _isGlobalLoading = true);
                try {
                  bool success = await _viewModel.deleteFolder(folderId);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã xóa thư mục.')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isGlobalLoading = false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      extendBodyBehindAppBar: true,
      floatingActionButton:
          _isGlobalLoading
              ? null
              : Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: primaryPink.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: _showCreateFolderDialog,
                  tooltip: 'Tạo thư mục mới',
                  icon: const Icon(Icons.add_rounded, size: 28),
                  label: const Text(
                    'Thư mục mới',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  backgroundColor: primaryPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  elevation: 0,
                ),
              ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                Theme.of(context).brightness == Brightness.dark
                    ? [
                      const Color(0xFF121212),
                      const Color(0xFF1E1E1E),
                      const Color(0xFF2C2C2C),
                    ]
                    : [
                      const Color(0xFFFCE4EC), // Very Light Pink
                      const Color(0xFFF8BBD0), // Light Pink
                      const Color(0xFFF48FB1), // Medium Pink accent
                    ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              top: -80,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 150,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Custom App Bar Area
                  _buildCustomAppBar(),

                  // Main Content
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _viewModel,
                      builder: (context, child) {
                        // Loading (Initial)
                        if (_viewModel.isBusy && !_isGlobalLoading) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }

                        // Error
                        if (_viewModel.errorMessage.isNotEmpty &&
                            !_isGlobalLoading) {
                          return Center(
                            child: Container(
                              margin: const EdgeInsets.all(24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).cardColor.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.amber,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _viewModel.errorMessage,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withValues(alpha: 0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed:
                                        _viewModel.loadUserDataAndFetchFolders,
                                    child: const Text(
                                      'Thử lại',
                                      style: TextStyle(color: primaryPink),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Content List
                        return RefreshIndicator(
                          onRefresh: _viewModel.loadUserDataAndFetchFolders,
                          color: primaryPink,
                          backgroundColor: Theme.of(context).cardColor,
                          child: Column(
                            children: [
                              // Dictionary Search Bar
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  10,
                                  20,
                                  20,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).cardColor.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).shadowColor.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _dictionarySearchController,
                                    decoration: InputDecoration(
                                      hintText: 'Tra từ điển Anh - Anh nhanh',
                                      hintStyle: TextStyle(
                                        color: Colors.grey[400],
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search_rounded,
                                        color: primaryPink,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 15,
                                          ),
                                    ),
                                    onSubmitted:
                                        (_) => _handleDictionarySearch(),
                                  ),
                                ),
                              ),

                              // Folder Section Header
                              _buildFolderHeader(),

                              // Folder Grid/List
                              Expanded(child: _buildFolderList()),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Global Loading Overlay
            if (_isGlobalLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                icon: const Icon(Icons.menu_rounded, color: primaryPink),
                tooltip: 'Menu',
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _viewModel,
            builder:
                (context, child) => Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: RichText(
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color ??
                                  const Color(0xFF555555),
                            ),
                            children: [const TextSpan(text: 'Helen chào bạn!')],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('👋', style: TextStyle(fontSize: 22)),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF1E1E1E), const Color(0xFF2C2C2C)]
                    : [const Color(0xFFFCE4EC), Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryPink, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).cardColor,
                      child: Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: primaryPink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _viewModel,
                    builder:
                        (context, child) => Text(
                          _viewModel.username ?? 'Nguời dùng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enjoy Learning!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildDrawerItem(
                    icon: Icons.settings_rounded,
                    title: 'Cài đặt',
                    onTap: () {
                      Navigator.of(context).pop();
                      _handleSettingsTap(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Về ứng dụng',
                    onTap: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'English Learning App',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(
                          Icons.school_rounded,
                          color: primaryPink,
                        ),
                        children: [
                          const Text('Ứng dụng học tiếng Anh hiệu quả.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Logout Button Area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryPink.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryPink, size: 22),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      const Color(0xFF444444),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderList() {
    if (_viewModel.folders.isEmpty &&
        _folderSearchController.text.trim().isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  size: 80,
                  color: primaryPink.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Chưa có thư mục nào',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tạo thư mục đầu tiên để bắt đầu học nhé!',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewModel.folders.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy thư mục nào.',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        100,
      ), // Bottom padding for FAB
      itemCount: _viewModel.folders.length + (_viewModel.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _viewModel.folders.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final folder = _viewModel.folders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) => VocabularyListView(
                          folderId: folder.id,
                          folderName: folder.name,
                        ),
                  ),
                );
                if (result == true) {
                  _viewModel.loadUserDataAndFetchFolders();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Icon Container
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.withOpacity(0.1)
                                : const Color(0xFFFFF0F5), // ultra light pink
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.folder_rounded,
                        color: primaryPink,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Text Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            folder.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.style_outlined,
                                size: 14,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${folder.vocabularyCount} từ vựng',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Menu Button
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Colors.grey[400],
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDialog(folder);
                        } else if (value == 'delete') {
                          _showDeleteDialog(folder.id);
                        }
                      },
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_rounded,
                                    color: primaryPink,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Sửa tên',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_rounded,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Xóa',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFolderHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child:
            _isSearchingFolders
                ? Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    key: const ValueKey('folderSearchField'),
                    controller: _folderSearchController,
                    focusNode: _folderSearchFocusNode,
                    onChanged: _viewModel.onSearchChanged,
                    autofocus: true,
                    style: const TextStyle(
                      color: primaryPink,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Nhập tên thư mục...',
                      hintStyle: TextStyle(color: primaryPink.withOpacity(0.5)),
                      prefixIcon: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: primaryPink,
                        ),
                        onPressed: _toggleFolderSearch,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
                : Row(
                  key: const ValueKey('folderHeader'),
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Thư mục của bạn',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: (Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color ??
                                    const Color(0xFF333333))
                                .withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_viewModel.folders.length}',
                            style: const TextStyle(
                              color: primaryPink,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.search_rounded,
                        color: primaryPink,
                      ),
                      onPressed: _toggleFolderSearch,
                      tooltip: 'Tìm thư mục',
                    ),
                  ],
                ),
      ),
    );
  }

  Future<void> _handleSettingsTap(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDark = themeProvider.themeMode == ThemeMode.dark;
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cài đặt',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dark Mode Toggle
                  SwitchListTile(
                    title: const Text('Chế độ tối (Dark Mode)'),
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: isDark ? Colors.white : Colors.orange,
                    ),
                    value: isDark,
                    onChanged: (bool value) {
                      themeProvider.toggleTheme(value);
                    },
                  ),

                  const Divider(),

                  // TTS Settings
                  ListTile(
                    leading: const Icon(
                      Icons.speed_rounded,
                      color: primaryPink,
                    ),
                    title: const Text('Tốc độ đọc (TTS)'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () async {
                      Navigator.pop(context); // Close main settings
                      final ttsService = TextToSpeechService();
                      await ttsService.init();
                      if (context.mounted) {
                        showSpeechRateBottomSheet(context, ttsService);
                      }
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
