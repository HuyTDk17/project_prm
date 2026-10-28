import 'package:flutter/foundation.dart';

import '../../../shared/models/video.dart';
import '../data/video_repository.dart';

enum LoadStatus { loading, success, empty, error }

/// State of the home feed: categories, selected category and the video list.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._repository);

  static const allCategories = 'All';

  final VideoRepository _repository;

  List<String> _categories = const [allCategories];
  String _selected = allCategories;
  List<Video> _videos = const [];
  LoadStatus _status = LoadStatus.loading;

  // Ignores answers of requests that were replaced by a newer one.
  int _requestId = 0;
  bool _disposed = false;

  List<String> get categories => _categories;
  String get selectedCategory => _selected;
  List<Video> get videos => _videos;
  LoadStatus get status => _status;

  Future<void> load() async {
    try {
      final names = await _repository.getCategories();
      _categories = [allCategories, ...names];
    } catch (_) {
      // The feed can still work with "All" only.
    }
    await _fetch();
  }

  Future<void> selectCategory(String category) async {
    if (category == _selected) return;
    _selected = category;
    notifyListeners();
    await _fetch();
  }

  /// Pull-to-refresh: keeps the current list on screen while loading.
  Future<void> refresh() => _fetch(showLoading: false);

  Future<void> _fetch({bool showLoading = true}) async {
    final id = ++_requestId;
    if (showLoading) {
      _status = LoadStatus.loading;
      notifyListeners();
    }
    try {
      final result = await _repository.getPublicVideos(
        category: _selected == allCategories ? null : _selected,
      );
      if (id != _requestId || _disposed) return;
      _videos = result;
      _status = result.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (_) {
      if (id != _requestId || _disposed) return;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
