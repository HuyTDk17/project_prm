import '../../../shared/models/app_notification.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/channel.dart';
import '../../../shared/models/comment.dart';
import '../../../shared/models/video.dart';

/// Everything a registered user does around videos: views, likes, comments,
/// subscriptions, history and notifications. The Firestore version is used by
/// the app; the in-memory version below is used by tests.
abstract class EngagementRepository {
  Future<Video?> getVideo(String id);

  /// BR09 + BR13: +1 view; for a logged-in user also writes the watch history.
  Future<void> recordView(Video video, {String? userId});

  Future<bool> isLiked(String userId, String videoId);
  Future<void> setLiked({required String userId, required Video video, required bool liked});

  Future<List<Comment>> getComments(String videoId);
  Future<Comment> addComment({required Video video, required AppUser user, required String text});
  Future<void> deleteComment({required String videoId, required String commentId});

  Future<bool> isSubscribed(String userId, String channelId);
  Future<int> subscriberCount(String channelId);
  Future<void> setSubscribed({
    required AppUser user,
    required String channelId,
    required String channelName,
    required String ownerId,
    required bool subscribe,
  });

  Future<List<Video>> getHistory(String userId);
  Future<void> removeHistory(String userId, String videoId);
  Future<void> clearHistory(String userId);
  Future<List<Video>> getLiked(String userId);
  Future<List<Channel>> getSubscriptions(String userId);

  Future<List<AppNotification>> getNotifications(String userId);
  Future<void> markNotificationRead(String userId, String notificationId);
  Future<void> markAllNotificationsRead(String userId);
}

/// Small in-memory implementation (tests and offline preview).
class MockEngagementRepository implements EngagementRepository {
  final Set<String> _liked = {};
  final Set<String> _subscribed = {};
  final Map<String, List<Comment>> _comments = {};

  @override
  Future<Video?> getVideo(String id) async => null;
  @override
  Future<void> recordView(Video video, {String? userId}) async {}
  @override
  Future<bool> isLiked(String userId, String videoId) async => _liked.contains('$userId/$videoId');
  @override
  Future<void> setLiked({required String userId, required Video video, required bool liked}) async {
    final key = '$userId/${video.id}';
    liked ? _liked.add(key) : _liked.remove(key);
  }

  @override
  Future<List<Comment>> getComments(String videoId) async => List.of(_comments[videoId] ?? const []);
  @override
  Future<Comment> addComment({required Video video, required AppUser user, required String text}) async {
    final c = Comment(
      id: 'c${DateTime.now().microsecondsSinceEpoch}',
      authorId: user.id,
      authorName: user.displayName,
      content: text,
      createdAt: DateTime.now(),
    );
    (_comments[video.id] ??= []).insert(0, c);
    return c;
  }

  @override
  Future<void> deleteComment({required String videoId, required String commentId}) async =>
      _comments[videoId]?.removeWhere((c) => c.id == commentId);
  @override
  Future<bool> isSubscribed(String userId, String channelId) async => _subscribed.contains('$userId/$channelId');
  @override
  Future<int> subscriberCount(String channelId) async => 0;
  @override
  Future<void> setSubscribed({
    required AppUser user,
    required String channelId,
    required String channelName,
    required String ownerId,
    required bool subscribe,
  }) async {
    final key = '${user.id}/$channelId';
    subscribe ? _subscribed.add(key) : _subscribed.remove(key);
  }

  @override
  Future<List<Video>> getHistory(String userId) async => const [];
  @override
  Future<void> removeHistory(String userId, String videoId) async {}
  @override
  Future<void> clearHistory(String userId) async {}
  @override
  Future<List<Video>> getLiked(String userId) async => const [];
  @override
  Future<List<Channel>> getSubscriptions(String userId) async => const [];
  @override
  Future<List<AppNotification>> getNotifications(String userId) async => const [];
  @override
  Future<void> markNotificationRead(String userId, String notificationId) async {}
  @override
  Future<void> markAllNotificationsRead(String userId) async {}
}
