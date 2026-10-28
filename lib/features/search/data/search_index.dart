import '../../../shared/models/video.dart';
import '../../home/data/video_repository.dart';

/// The public videos used for searching. They are read once and kept for a
/// minute, so opening the search page again costs no new Firestore read.
class SearchIndex {
  SearchIndex(this._videos);

  final VideoRepository _videos;

  List<Video>? _cache;
  DateTime? _loadedAt;
  Future<List<Video>>? _inflight;

  static const _ttl = Duration(seconds: 60);

  Future<List<Video>> videos({bool force = false}) {
    final fresh = _cache != null && _loadedAt != null && DateTime.now().difference(_loadedAt!) < _ttl;
    if (!force && fresh) return Future.value(_cache!);
    return _inflight ??= _fetch().whenComplete(() => _inflight = null);
  }

  Future<List<Video>> _fetch() async {
    final list = await _videos.getPublicVideos();
    _cache = list;
    _loadedAt = DateTime.now();
    return list;
  }

  Future<List<String>> categories() => _videos.getCategories();
}
