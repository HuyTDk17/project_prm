import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../shared/models/video.dart';
import '../../home/data/video_mapper.dart';
import 'channel_repository.dart';

class FirestoreChannelRepository implements ChannelRepository {
  FirestoreChannelRepository({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<ChannelInfo?> getChannel(String id) async {
    final doc = await _db.collection('channels').doc(id).get();
    final m = doc.data();
    if (m == null) return null;
    return ChannelInfo(
      id: doc.id,
      ownerId: (m['ownerId'] as String?) ?? '',
      name: (m['name'] as String?) ?? '',
      description: (m['description'] as String?) ?? '',
      subscriberCount: (m['subscriberCount'] as num?)?.toInt() ?? 0,
      avatarUrl: m['avatarUrl'] as String?,
      bannerUrl: m['bannerUrl'] as String?,
    );
  }

  @override
  Future<List<Video>> getVideos(String channelId) async {
    // Equality filters only (no composite index); sorted here, newest first.
    final snap = await _db
        .collection('videos')
        .where('channelId', isEqualTo: channelId)
        .where('visibility', isEqualTo: 'public')
        .limit(100)
        .get();
    return snap.docs.map((d) => videoFromMap(d.id, d.data())).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
