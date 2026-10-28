import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/models/comment.dart';
import '../../../shared/models/video.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/channel_store.dart';
import '../../home/data/video_mapper.dart';
import '../../home/data/video_notifications.dart';
import 'studio_repository.dart';

class FirestoreStudioRepository implements StudioRepository {
  FirestoreStudioRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<List<Video>> getChannelVideos({required String ownerId, required String channelId}) async {
    // The ownerId filter lets the security rules allow the query for private videos.
    final snap = await _db
        .collection('videos')
        .where('ownerId', isEqualTo: ownerId)
        .where('channelId', isEqualTo: channelId)
        .limit(200)
        .get();
    return snap.docs.map((d) => videoFromMap(d.id, d.data())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> updateVideo(
    Video video, {
    required String title,
    required String description,
    required String category,
    required bool isPublic,
    String? thumbnailUrl,
  }) async {
    final ref = _db.collection('videos').doc(video.id);
    final before = await ref.get();
    final alreadyNotified = before.data()?['notified'] == true;
    await ref.update({
      'title': title,
      'description': description,
      'categoryName': category,
      'visibility': isPublic ? 'public' : 'private',
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
      if (isPublic) 'notified': true,
    });
    final channelId = video.channelId;
    if (isPublic && !alreadyNotified && channelId != null) {
      await notifySubscribers(
        _db,
        videoId: video.id,
        channelId: channelId,
        channelName: video.channelName,
        ownerId: video.ownerId,
        title: title,
      );
    }
  }

  @override
  Future<void> deleteVideo(Video video) async {
    final ref = _db.collection('videos').doc(video.id);
    // Sub-collections first: their security rules look at the video document.
    for (final name in ['comments', 'likes']) {
      final snap = await ref.collection(name).limit(400).get();
      if (snap.docs.isEmpty) continue;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await ref.delete();
  }

  @override
  Future<List<ModerationComment>> getComments(List<Video> videos) async {
    final latest = videos.take(20).toList();
    final lists = await Future.wait(latest.map((v) async {
      final snap = await _db
          .collection('videos')
          .doc(v.id)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();
      return snap.docs.map((d) {
        final m = d.data();
        final created = m['createdAt'];
        return ModerationComment(
          videoId: v.id,
          videoTitle: v.title,
          comment: Comment(
            id: d.id,
            authorId: (m['authorId'] as String?) ?? '',
            authorName: (m['authorName'] as String?) ?? 'User',
            content: (m['content'] as String?) ?? '',
            createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
          ),
        );
      }).toList();
    }));
    return [for (final l in lists) ...l]
      ..sort((a, b) => b.comment.createdAt.compareTo(a.comment.createdAt));
  }

  @override
  Future<void> updateChannel({
    required String channelId,
    required String ownerId,
    required String oldName,
    required String name,
    required String description,
    String? avatarUrl,
    String? bannerUrl,
  }) async {
    final newKey = ChannelStore.keyFor(name);
    final oldKey = ChannelStore.keyFor(oldName);
    final renamed = newKey != oldKey;
    await _db.runTransaction((tx) async {
      if (renamed) {
        final newRef = _db.collection('channelNames').doc(newKey);
        if ((await tx.get(newRef)).exists) throw const ChannelException(AppStrings.channelNameTaken);
        tx.delete(_db.collection('channelNames').doc(oldKey));
        tx.set(newRef, {'channelId': channelId, 'ownerId': ownerId});
      }
      tx.update(_db.collection('channels').doc(channelId), {
        'name': name,
        'description': description,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (bannerUrl != null) 'bannerUrl': bannerUrl,
      });
    });
    if (renamed) {
      // The channel name is also stored on each video (shown in the feed).
      final videos = await _db
          .collection('videos')
          .where('ownerId', isEqualTo: ownerId)
          .where('channelId', isEqualTo: channelId)
          .limit(400)
          .get();
      if (videos.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final d in videos.docs) {
          batch.update(d.reference, {'channelName': name});
        }
        await batch.commit();
      }
    }
  }
}
