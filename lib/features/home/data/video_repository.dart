import '../../../shared/models/video.dart';
import '../../../shared/models/video_draft.dart';

/// Source of videos. The mock below is replaced by SQLite later.
abstract class VideoRepository {
  Future<List<String>> getCategories();

  /// Public videos, newest first. [category] = null means all categories.
  Future<List<Video>> getPublicVideos({String? category});

  /// Saves a new video (BR06). Files are already uploaded; only addresses are stored.
  Future<void> createVideo(VideoDraft draft);
}

class MockVideoRepository implements VideoRepository {
  static const _categories = ['Education', 'Gaming', 'Music', 'Sports', 'Entertainment', 'News'];

  late final List<Video> _videos = _seed();
  int _nextId = 1000;

  List<Video> _seed() {
    final now = DateTime.now();
    Video v(int id, String title, String channel, String category, int sec, int views, Duration age) {
      return Video(
        id: 'v$id',
        title: title,
        channelName: channel,
        categoryName: category,
        durationSec: sec,
        viewCount: views,
        createdAt: now.subtract(age),
      );
    }

    return [
      v(1, 'Build your first Flutter app in 30 minutes', 'Code Academy', 'Education', 1830, 128400, const Duration(hours: 5)),
      v(2, 'Lo-fi beats for late-night coding', 'Music Hub', 'Music', 3540, 902300, const Duration(days: 1)),
      v(3, 'Speedrun: finishing a platformer in 9 minutes', 'Pixel Lab', 'Gaming', 604, 56800, const Duration(days: 2)),
      v(4, 'State management explained with Provider', 'Dev Simple', 'Education', 912, 80250, const Duration(days: 3)),
      v(5, 'Ten drills to improve your sprint start', 'Track Notes', 'Sports', 727, 23400, const Duration(days: 4)),
      v(6, 'A day in the life of a mobile developer', 'Dev Simple', 'Entertainment', 1105, 310900, const Duration(days: 6)),
      v(7, 'Weekly tech news: what changed in Flutter', 'Tech Brief', 'News', 488, 41200, const Duration(days: 8)),
      v(8, 'Designing a clean UI with Material 3', 'Code Academy', 'Education', 1320, 97600, const Duration(days: 12)),
      v(9, 'Indie game soundtrack: the making of', 'Music Hub', 'Music', 2210, 18700, const Duration(days: 20)),
      v(10, 'Cooperative puzzle games worth playing', 'Pixel Lab', 'Gaming', 1405, 64100, const Duration(days: 35)),
      v(11, 'Marathon training: the first four weeks', 'Track Notes', 'Sports', 1680, 12900, const Duration(days: 60)),
      v(12, 'Short film: the last bus home', 'Night Shift', 'Entertainment', 934, 2300000, const Duration(days: 400)),
    ];
  }

  @override
  Future<List<String>> getCategories() async => _categories;

  @override
  Future<List<Video>> getPublicVideos({String? category}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final list = category == null
        ? _videos
        : _videos.where((v) => v.categoryName == category).toList();
    return List.unmodifiable(list);
  }

  @override
  Future<void> createVideo(VideoDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!draft.isPublic) return;
    _videos.insert(
      0,
      Video(
        id: 'v${_nextId++}',
        title: draft.title,
        channelName: draft.channelName,
        channelId: draft.channelId,
        categoryName: draft.categoryName,
        durationSec: draft.durationSec,
        viewCount: 0,
        createdAt: DateTime.now(),
        videoUrl: draft.videoUrl,
        thumbnailPath: draft.thumbnailUrl,
      ),
    );
  }
}
