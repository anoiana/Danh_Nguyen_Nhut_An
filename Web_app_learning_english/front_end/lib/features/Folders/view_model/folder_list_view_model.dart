import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/base_view_model.dart';
import '../model/folder.dart';
import '../service/folder_service.dart';

class FolderListViewModel extends BaseViewModel {
  List<Folder> _folders = [];
  List<Folder> get folders => _folders;

  int? _userId;
  String? _username;
  String? get username => _username;

  // Pagination & Search State
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';
  Timer? _debounce;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  // Initial Load
  Future<void> loadUserDataAndFetchFolders() async {
    setBusy(true);
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
    _username = prefs.getString('username');

    if (_userId == null) {
      setError("User not logged in");
      setBusy(false);
      return;
    }

    await _resetAndFetchFolders();
    setBusy(false);
  }

  Future<void> _resetAndFetchFolders() async {
    _folders.clear();
    _currentPage = 0;
    _hasMore = true;

    try {
      final folderPage = await FolderService.getFoldersByUser(
        _userId!,
        page: _currentPage,
        search: _searchQuery,
      );

      _folders = folderPage.content;
      _hasMore = !folderPage.isLast;
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }

  void onSearchChanged(String query) {
    _searchQuery = query.trim();
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _resetAndFetchFolders(); // Trigger fetch
    });
  }

  Future<void> fetchMoreFolders() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final folderPage = await FolderService.getFoldersByUser(
        _userId!,
        page: _currentPage,
        search: _searchQuery,
      );

      _folders.addAll(folderPage.content);
      _hasMore = !folderPage.isLast;
    } catch (e) {
      // Silent error for pagination or show snackbar via view
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createFolder(String name) async {
    if (_userId == null) return false;
    try {
      await FolderService.createFolder(name, _userId!);
      await _resetAndFetchFolders();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<bool> updateFolder(int folderId, String newName) async {
    try {
      await FolderService.updateFolder(folderId, newName);
      await _resetAndFetchFolders();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteFolder(int folderId) async {
    try {
      await FolderService.deleteFolder(folderId);
      await _resetAndFetchFolders();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
