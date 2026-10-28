import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/video.dart';
import '../../../shared/models/video_draft.dart';
import 'video_mapper.dart';
import 'video_notifications.dart';
import 'video_repository.dart';

/// Public videos from Cloud Firestore (collection `videos`).
class FirestoreVideoRepository implements VideoRepository {
  FirestoreVideoRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const categories = ['Education', 'Gaming', 'Music', 'Sports', 'Entertainment', 'News'];

  @override
  Future<List<String>> getCategories() async => categories;

  @override
  Future<List<Video>> getPublicVideos({String? category}) async {
    // Only equality filters, so no composite index is needed; the list is
    // sorted here (newest first, BR16).
    Query<Map<String, dynamic>> query =
        _db.collection('videos').where('visibility', isEqualTo: 'public');
    if (category != null) query = query.where('categoryName', isEqualTo: category);
    final snap = await query.limit(100).get();
    final videos = snap.docs.map(_fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return videos;
  }

  Video _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) => videoFromMap(doc.id, doc.data());

  @override
  Future<void> createVideo(VideoDraft draft) async {
    final ref = await _db.collection('videos').add({
      'ownerId': draft.ownerId,
      'channelId': draft.channelId,
      'channelName': draft.channelName,
      'title': draft.title,
      'description': draft.description,
      'categoryName': draft.categoryName,
      'videoUrl': draft.videoUrl,
      'thumbnailUrl': draft.thumbnailUrl,
      'durationSec': draft.durationSec,
      'visibility': draft.isPublic ? 'public' : 'private',
      'notified': draft.isPublic,
      'viewCount': 0,
      'likeCount': 0,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (draft.isPublic) {
      await notifySubscribers(
        _db,
        videoId: ref.id,
        channelId: draft.channelId,
        channelName: draft.channelName,
        ownerId: draft.ownerId,
        title: draft.title,
      );
    }
  }
}
