import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/models/video.dart';
import '../data/recent_searches.dart';
import '../data/search_index.dart';
import '../data/search_service.dart';

/// State of the search page: query, filters, results and recent searches.
/// Typing searches after a short pause (debounce); everything runs in memory.
class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required SearchIndex index,
    required RecentSearches recent,
    String initialQuery = '',
  })  : _index = index,
        _recent = recent,
        _query = initialQuery {
    _load();
  }

  static const _debounce = Duration(milliseconds: 220);

  final SearchIndex _index;
  final RecentSearches _recent;

  String _query;
  String _category = 'All';
  SearchSort _sort = SearchSort.relevance;
  List<Video> _corpus = const [];
  List<String> _categories = const ['All'];
  List<String> _recentQueries = const [];
  List<Video> _results = const [];
  List<ChannelHit> _channels = const [];
  bool _loading = true;
  String? _error;
  Timer? _timer;
  bool _disposed = false;

  String get query => _query;
  String get category => _category;
  SearchSort get sort => _sort;
  List<String> get categories => _categories;
  List<String> get recentQueries => _recentQueries;
  List<Video> get results => _results;
  List<ChannelHit> get channels => _channels;
  bool get isLoading => _loading;
  String? get error => _error;

  /// True when there is something to search for (a query or a category).
  bool get hasCriteria => _query.trim().isNotEmpty || _category != 'All';

  Future<void> _load() async {
    try {
      final loaded = await Future.wait([
        _index.videos(),
        _index.categories(),
        _recent.load(),
      ]);
      _corpus = loaded[0] as List<Video>;
      _categories = ['All', ...(loaded[1] as List<String>)];
      _recentQueries = loaded[2] as List<String>;
      _error = null;
      _apply();
    } catch (_) {
      _error = AppStrings.genericError;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> retry() {
    _loading = true;
    _error = null;
    notifyListeners();
    return _load();
  }

  /// Called on every key press; the search itself waits for a short pause.
  void onQueryChanged(String value) {
    _query = value;
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      _apply();
      notifyListeners();
    });
    notifyListeners();
  }

  /// Enter key or tap on a recent search: search now and remember the query.
  Future<void> submit(String value) async {
    _timer?.cancel();
    _query = value;
    _apply();
    notifyListeners();
    _recentQueries = await _recent.add(value);
    notifyListeners();
  }

  /// Remember the query when the user opens a result.
  Future<void> commit() async {
    if (_query.trim().length < 2) return;
    _recentQueries = await _recent.add(_query);
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    _apply();
    notifyListeners();
  }

  void setSort(SearchSort value) {
    _sort = value;
    _apply();
    notifyListeners();
  }

  void clearFilters() {
    _category = 'All';
    _sort = SearchSort.relevance;
    _apply();
    notifyListeners();
  }

  Future<void> removeRecent(String value) async {
    _recentQueries = await _recent.remove(value);
    notifyListeners();
  }

  Future<void> clearRecent() async {
    await _recent.clear();
    _recentQueries = const [];
    notifyListeners();
  }

  void _apply() {
    if (!hasCriteria) {
      _results = const [];
      _channels = const [];
      return;
    }
    _results = SearchService.search(_corpus, _query, category: _category, sort: _sort);
    _channels = _category == 'All' ? SearchService.channels(_corpus, _query) : const [];
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
