import 'package:cloud_firestore/cloud_firestore.dart';

/// BR08: one NEW_VIDEO notification for each subscriber of the channel.
/// Failures are ignored: the video is already saved.
Future<void> notifySubscribers(
  FirebaseFirestore db, {
  required String videoId,
  required String channelId,
  required String channelName,
  required String ownerId,
  required String title,
}) async {
  try {
    final subs = await db.collection('channels').doc(channelId).collection('subscribers').get();
    var batch = db.batch();
    var count = 0;
    for (final sub in subs.docs) {
      if (sub.id == ownerId) continue;
      batch.set(db.collection('users').doc(sub.id).collection('notifications').doc(), {
        'type': 'NEW_VIDEO',
        'message': '$channelName uploaded "$title"',
        'videoId': videoId,
        'channelId': channelId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (++count % 400 == 0) {
        await batch.commit();
        batch = db.batch();
      }
    }
    await batch.commit();
  } catch (_) {}
}
