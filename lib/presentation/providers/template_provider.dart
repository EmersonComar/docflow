import 'package:flutter/foundation.dart';
import '../../domain/entities/template.dart';
import '../../domain/entities/template_sort_option.dart';
import '../../domain/repositories/template_repository.dart';

class TemplateProvider extends ChangeNotifier {
  final TemplateRepository _repository;

  List<Template> _templates = [];
  List<String> _allTags = [];
  List<(String name, int count)> _tagCounts = [];
  final Map<String, bool> _selectedTags = {};
  final Set<int> _expandedTemplateIds = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isInitialized = false;
  (String, List<Object>)? _error;
  String _searchQuery = '';
  TemplateSortOption _sortOption = TemplateSortOption.recentlyUpdated;

  final int _pageSize = 10;
  int _page = 0;
  bool _hasMore = true;

  TemplateProvider(this._repository);

  List<Template> get templates => _templates;
  List<String> get allTags => _allTags;
  List<(String name, int count)> get tagCounts => _tagCounts;
  Map<String, bool> get selectedTags => _selectedTags;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isInitialized => _isInitialized;
  (String, List<Object>)? get error => _error;
  bool get hasMore => _hasMore;
  TemplateSortOption get sortOption => _sortOption;

  bool isTemplateExpanded(int? templateId) {
    return templateId != null && _expandedTemplateIds.contains(templateId);
  }

  void toggleTemplateExpansion(int? templateId) {
    if (templateId == null) return;

    if (_expandedTemplateIds.contains(templateId)) {
      _expandedTemplateIds.remove(templateId);
    } else {
      _expandedTemplateIds.add(templateId);
    }
    notifyListeners();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.ensureInitialized();

    if (result.isFailure) {
      _error = (result.failure.messageKey, result.failure.messageArgs);
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isInitialized = true;
    await refreshTemplates();
  }

  Future<void> refreshTemplates() async {
    _isLoading = true;
    _error = null;
    _page = 0;
    _hasMore = true;
    _templates = [];
    notifyListeners();

    try {
      final tagsResult = await _repository.getAllTags();
      if (tagsResult.isSuccess) {
        _allTags = tagsResult.data;
      }

      try {
        final countsResult = await _repository.getTagCounts();
        if (countsResult.isSuccess) {
          _tagCounts = countsResult.data;
        }
      } catch (_) {}

      final activeTags = _selectedTags.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final templatesResult = await _repository.getTemplates(
        limit: _pageSize,
        offset: 0,
        tags: activeTags,
        searchQuery: _searchQuery,
        sortOption: _sortOption,
      );

      if (templatesResult.isSuccess) {
        _templates = templatesResult.data;
        _hasMore = _templates.length >= _pageSize;
      } else {
        _error = (templatesResult.failure.messageKey, templatesResult.failure.messageArgs);
      }
    } catch (e) {
      _error = ('unexpectedError', [e.toString()]);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _page++;
      final activeTags = _selectedTags.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final result = await _repository.getTemplates(
        limit: _pageSize,
        offset: _page * _pageSize,
        tags: activeTags,
        searchQuery: _searchQuery,
        sortOption: _sortOption,
      );

      if (result.isSuccess) {
        final newTemplates = result.data;
        _templates.addAll(newTemplates);
        _hasMore = newTemplates.length >= _pageSize;
      } else {
        _error = (result.failure.messageKey, result.failure.messageArgs);
      }
    } catch (e) {
      _error = ('loadMoreFailed', [e.toString()]);
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    refreshTemplates();
  }

  void updateTag(String tag, bool value) {
    _selectedTags[tag] = value;
    refreshTemplates();
  }

  void setSortOption(TemplateSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    refreshTemplates();
  }

  Future<void> togglePinned(Template template) async {
    if (template.id == null) return;

    final result = await _repository.setPinned(template.id!, !template.pinned);
    if (result.isSuccess) {
      await refreshTemplates();
    } else {
      _error = (result.failure.messageKey, result.failure.messageArgs);
      notifyListeners();
    }
  }

  Future<void> addTemplate(Template template) async {
    final result = await _repository.create(template);

    if (result.isSuccess) {
      await refreshTemplates();
    } else {
      _error = (result.failure.messageKey, result.failure.messageArgs);
      notifyListeners();
    }
  }

  Future<void> updateTemplate(Template template) async {
    final result = await _repository.update(template);
    if (result.isSuccess) {
      final activeTags = _selectedTags.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      if (activeTags.isNotEmpty) {
        final templatesResult = await _repository.getTemplates(
          tags: activeTags,
          searchQuery: _searchQuery,
        );
        if (templatesResult.isSuccess && templatesResult.data.isEmpty) {
          _selectedTags.clear();
        }
      }
      await refreshTemplates();
    } else {
      _error = (result.failure.messageKey, result.failure.messageArgs);
      notifyListeners();
    }
  }

  Future<void> deleteTemplate(int id) async {
    final result = await _repository.delete(id);
    if (result.isSuccess) {
      final activeTags = _selectedTags.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      if (activeTags.isNotEmpty) {
        final templatesResult = await _repository.getTemplates(
          tags: activeTags,
          searchQuery: _searchQuery,
        );
        if (templatesResult.isSuccess && templatesResult.data.isEmpty) {
          _selectedTags.clear();
        }
      }
      await refreshTemplates();
    } else {
      _error = (result.failure.messageKey, result.failure.messageArgs);
      notifyListeners();
    }
  }
}
