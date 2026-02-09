import 'dart:async';
import '../../../core/base_view_model.dart';
import '../model/vocabulary.dart';
import '../service/vocabulary_service.dart';

class VocabularyViewModel extends BaseViewModel {
  // Data State
  List<Vocabulary> _vocabularies = [];
  List<Vocabulary> get vocabularies => _vocabularies;

  // Folder Info
  int _folderId = 0;
  String _folderName = '';

  // Pagination & Search
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<int> _selectedVocabIds = {};

  bool get isSelectionMode => _isSelectionMode;
  Set<int> get selectedVocabIds => _selectedVocabIds;

  // Changes Flag
  bool _hasChanges = false;
  bool get hasChanges => _hasChanges;

  // Total Count
  int _totalVocabulariesCount = 0;
  int get totalVocabulariesCount => _totalVocabulariesCount;

  // Init
  void init(int folderId, String folderName) {
    _folderId = folderId;
    _folderName = folderName;
    _vocabularies.clear();
    _currentPage = 0;
    _hasMore = true;
    _hasChanges = false;
    _selectedVocabIds.clear();
    _isSelectionMode = false;
    fetchVocabularies();
  }

  Future<void> fetchVocabularies({bool refresh = true}) async {
    if (refresh) {
      setBusy(true);
      _currentPage = 0;
      _vocabularies.clear();
      _selectedVocabIds.clear();
    } else {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final vocabPage = await VocabularyService.getVocabulariesByFolder(
        _folderId,
        page: _currentPage,
        search: _searchQuery,
      );

      if (refresh) {
        _vocabularies = vocabPage.content;
      } else {
        _vocabularies.addAll(vocabPage.content);
      }

      _totalVocabulariesCount = vocabPage.totalElements;
      _hasMore = !vocabPage.isLast;
      if (!refresh) _currentPage++;

      setBusy(false);
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      setError(e.toString());
      setBusy(false);
      _isLoadingMore = false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchVocabularies(refresh: true);
  }

  // Selection Logic
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    _selectedVocabIds.clear();
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (_selectedVocabIds.contains(id)) {
      _selectedVocabIds.remove(id);
    } else {
      _selectedVocabIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    if (_selectedVocabIds.length < _vocabularies.length) {
      _selectedVocabIds.addAll(_vocabularies.map((e) => e.id));
    } else {
      _selectedVocabIds.clear();
    }
    notifyListeners();
  }

  // CRUD Operations
  Future<bool> deleteVocabulary(int id) async {
    try {
      await VocabularyService.deleteVocabulary(id);
      _vocabularies.removeWhere((element) => element.id == id);
      _hasChanges = true;
      notifyListeners();
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<bool> deleteSelectedVocabularies() async {
    try {
      await VocabularyService.deleteVocabularies(_selectedVocabIds.toList());
      _hasChanges = true;
      toggleSelectionMode(); // Exit selection mode
      fetchVocabularies(refresh: true); // Reload
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<bool> updateVocabulary({
    required int id,
    required String meaning,
    String? partOfSpeech,
    String? imageBase64,
    double? alignX,
    double? alignY,
  }) async {
    try {
      await VocabularyService.updateVocabulary(
        vocabularyId: id,
        userDefinedMeaning: meaning,
        userDefinedPartOfSpeech: partOfSpeech,
        userImageBase64: imageBase64,
        imageAlignmentX: alignX,
        imageAlignmentY: alignY,
      );
      _hasChanges = true;
      fetchVocabularies(refresh: true);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }

  Future<bool> moveVocabularies(int targetFolderId) async {
    try {
      await VocabularyService.moveVocabularies(
        _selectedVocabIds.toList(),
        targetFolderId,
      );
      _hasChanges = true;
      toggleSelectionMode();
      fetchVocabularies(refresh: true);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    }
  }
}
