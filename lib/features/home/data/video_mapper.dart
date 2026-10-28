import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/video.dart';

/// Converts Firestore documents to [Video] and back to a short summary
/// (used by history and liked lists, so they can be shown without extra reads).
Video videoFromMap(String id, Map<String, dynamic> m) {
  DateTime time(Object? v) => v is Timestamp ? v.toDate() : DateTime.now();
  int number(Object? v) => (v as num?)?.toInt() ?? 0;
  return Video(
    id: id,
    title: (m['title'] as String?) ?? '',
    description: (m['description'] as String?) ?? '',
    channelName: (m['channelName'] as String?) ?? '',
    channelId: m['channelId'] as String?,
    ownerId: (m['ownerId'] as String?) ?? '',
    categoryName: (m['categoryName'] as String?) ?? '',
    durationSec: number(m['durationSec']),
    viewCount: number(m['viewCount']),
    likeCount: number(m['likeCount']),
    commentCount: number(m['commentCount']),
    createdAt: time(m['createdAt']),
    isPublic: m['visibility'] != 'private',
    videoUrl: m['videoUrl'] as String?,
    thumbnailPath: m['thumbnailUrl'] as String?,
  );
}

Map<String, dynamic> videoSummary(Video v) => {
      'title': v.title,
      'description': v.description,
      'channelName': v.channelName,
      'channelId': v.channelId,
      'ownerId': v.ownerId,
      'categoryName': v.categoryName,
      'durationSec': v.durationSec,
      'viewCount': v.viewCount,
      'likeCount': v.likeCount,
      'commentCount': v.commentCount,
      'createdAt': Timestamp.fromDate(v.createdAt),
      'videoUrl': v.videoUrl,
      'thumbnailUrl': v.thumbnailPath,
    };
