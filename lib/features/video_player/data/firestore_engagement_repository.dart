import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/app_notification.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/channel.dart';
import '../../../shared/models/comment.dart';
import '../../../shared/models/video.dart';
import '../../home/data/video_mapper.dart';
import 'engagement_repository.dart';

/// Cloud Firestore layout used here:
///   videos/{id}                      counters: viewCount, likeCount, commentCount
///   videos/{id}/likes/{uid}          one document per like
///   videos/{id}/comments/{id}
///   channels/{id}/subscribers/{uid}  used to notify subscribers (BR08)
///   users/{uid}/history|liked|subscriptions|notifications
class FirestoreEngagementRepository implements EngagementRepository {
  FirestoreEngagementRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _video(String id) => _db.collection('videos').doc(id);
  CollectionReference<Map<String, dynamic>> _userCol(String uid, String name) =>
      _db.collection('users').doc(uid).collection(name);
  DateTime _time(Object? v) => v is Timestamp ? v.toDate() : DateTime.now();

  @override
  Future<Video?> getVideo(String id) async {
    try {
      final doc = await _video(id).get();
      final data = doc.data();
      return data == null ? null : videoFromMap(doc.id, data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> recordView(Video video, {String? userId}) async {
    try {
      await _video(video.id).update({'viewCount': FieldValue.increment(1)});
    } catch (_) {}
    if (userId == null) return;
    try {
      await _userCol(userId, 'history').doc(video.id).set({
        ...videoSummary(video),
        'watchedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  @override
  Future<bool> isLiked(String userId, String videoId) async =>
      (await _video(videoId).collection('likes').doc(userId).get()).exists;

  @override
  Future<void> setLiked({required String userId, required Video video, required bool liked}) async {
    final batch = _db.batch();
    final likeRef = _video(video.id).collection('likes').doc(userId);
    final libraryRef = _userCol(userId, 'liked').doc(video.id);
    if (liked) {
      batch.set(likeRef, {'at': FieldValue.serverTimestamp()});
      batch.set(libraryRef, {...videoSummary(video), 'likedAt': FieldValue.serverTimestamp()});
    } else {
      batch.delete(likeRef);
      batch.delete(libraryRef);
    }
    batch.update(_video(video.id), {'likeCount': FieldValue.increment(liked ? 1 : -1)});
    await batch.commit();
  }

  @override
  Future<List<Comment>> getComments(String videoId) async {
    final snap = await _video(videoId).collection('comments').orderBy('createdAt', descending: true).limit(100).get();
    return snap.docs.map((d) {
      final m = d.data();
      return Comment(
        id: d.id,
        authorId: (m['authorId'] as String?) ?? '',
        authorName: (m['authorName'] as String?) ?? 'User',
        content: (m['content'] as String?) ?? '',
        createdAt: _time(m['createdAt']),
      );
    }).toList();
  }

  @override
  Future<Comment> addComment({required Video video, required AppUser user, required String text}) async {
    final ref = _video(video.id).collection('comments').doc();
    final batch = _db.batch();
    batch.set(ref, {
      'authorId': user.id,
      'authorName': user.displayName,
      'content': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_video(video.id), {'commentCount': FieldValue.increment(1)});
    // BR14: tell the owner, unless the owner is the author.
    if (video.ownerId.isNotEmpty && video.ownerId != user.id) {
      batch.set(_userCol(video.ownerId, 'notifications').doc(), {
        'type': 'NEW_COMMENT',
        'message': '${user.displayName} commented on "${video.title}"',
        'videoId': video.id,
        'channelId': video.channelId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return Comment(id: ref.id, authorId: user.id, authorName: user.displayName, content: text, createdAt: DateTime.now());
  }

  @override
  Future<void> deleteComment({required String videoId, required String commentId}) async {
    final batch = _db.batch();
    batch.delete(_video(videoId).collection('comments').doc(commentId));
    batch.update(_video(videoId), {'commentCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  @override
  Future<bool> isSubscribed(String userId, String channelId) async =>
      (await _userCol(userId, 'subscriptions').doc(channelId).get()).exists;

  @override
  Future<int> subscriberCount(String channelId) async {
    final doc = await _db.collection('channels').doc(channelId).get();
    return (doc.data()?['subscriberCount'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> setSubscribed({
    required AppUser user,
    required String channelId,
    required String channelName,
    required String ownerId,
    required bool subscribe,
  }) async {
    final batch = _db.batch();
    final mine = _userCol(user.id, 'subscriptions').doc(channelId);
    final theirs = _db.collection('channels').doc(channelId).collection('subscribers').doc(user.id);
    if (subscribe) {
      batch.set(mine, {
        'channelId': channelId,
        'ownerId': ownerId,
        'channelName': channelName,
        'at': FieldValue.serverTimestamp(),
      });
      batch.set(theirs, {'at': FieldValue.serverTimestamp()});
      if (ownerId.isNotEmpty && ownerId != user.id) {
        batch.set(_userCol(ownerId, 'notifications').doc(), {
          'type': 'NEW_SUBSCRIBER',
          'message': '${user.displayName} subscribed to ${channelName}',
          'channelId': channelId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } else {
      batch.delete(mine);
      batch.delete(theirs);
    }
    batch.update(_db.collection('channels').doc(channelId), {'subscriberCount': FieldValue.increment(subscribe ? 1 : -1)});
    await batch.commit();
  }

  List<Video> _videos(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => videoFromMap(d.id, d.data())).toList();

  @override
  Future<List<Video>> getHistory(String userId) async =>
      _videos(await _userCol(userId, 'history').orderBy('watchedAt', descending: true).limit(100).get());

  @override
  Future<void> removeHistory(String userId, String videoId) => _userCol(userId, 'history').doc(videoId).delete();

  @override
  Future<void> clearHistory(String userId) async {
    final snap = await _userCol(userId, 'history').limit(400).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  @override
  Future<List<Video>> getLiked(String userId) async =>
      _videos(await _userCol(userId, 'liked').orderBy('likedAt', descending: true).limit(100).get());

  @override
  Future<List<Channel>> getSubscriptions(String userId) async {
    final snap = await _userCol(userId, 'subscriptions').orderBy('at', descending: true).limit(100).get();
    return snap.docs.map((d) {
      final m = d.data();
      return Channel(id: d.id, ownerId: (m['ownerId'] as String?) ?? '', name: (m['channelName'] as String?) ?? '');
    }).toList();
  }

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    final snap = await _userCol(userId, 'notifications').orderBy('createdAt', descending: true).limit(50).get();
    return snap.docs.map((d) {
      final m = d.data();
      return AppNotification(
        id: d.id,
        type: NotificationType.fromName(m['type'] as String?),
        message: (m['message'] as String?) ?? '',
        isRead: (m['isRead'] as bool?) ?? false,
        createdAt: _time(m['createdAt']),
        videoId: m['videoId'] as String?,
        channelId: m['channelId'] as String?,
      );
    }).toList();
  }

  @override
  Future<void> markNotificationRead(String userId, String notificationId) =>
      _userCol(userId, 'notifications').doc(notificationId).update({'isRead': true});

  @override
  Future<void> markAllNotificationsRead(String userId) async {
    final snap = await _userCol(userId, 'notifications').where('isRead', isEqualTo: false).limit(400).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
