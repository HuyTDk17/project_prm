import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/data/channel_store.dart';

/// Development helper: fills Firestore with demo channels and videos so the
/// feed is not empty. It runs once (a document `meta/seed` marks it as done).
/// The titles are only illustrative; the video files are public sample clips.
class FirestoreSeeder {
  FirestoreSeeder({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _base = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/';

  static const _channelNames = [
    'Code Academy',
    'Music Hub',
    'Pixel Lab',
    'Dev Simple',
    'Track Notes',
    'Tech Brief',
    'Night Shift',
  ];

  // channel index, title, category, sample file, duration (s), views, age (hours)
  static const _videos = <(int, String, String, String, int, int, int)>[
    (0, 'Build your first Flutter app in 30 minutes', 'Education', 'BigBuckBunny.mp4', 596, 128400, 5),
    (1, 'Lo-fi beats for late-night coding', 'Music', 'ElephantsDream.mp4', 653, 902300, 24),
    (2, 'Speedrun: finishing a platformer in 9 minutes', 'Gaming', 'Sintel.mp4', 888, 56800, 48),
    (3, 'State management explained with Provider', 'Education', 'TearsOfSteel.mp4', 734, 80250, 72),
    (4, 'Ten drills to improve your sprint start', 'Sports', 'ForBiggerBlazes.mp4', 15, 23400, 96),
    (3, 'A day in the life of a mobile developer', 'Entertainment', 'ForBiggerEscapes.mp4', 15, 310900, 144),
    (5, 'Weekly tech news: what changed in Flutter', 'News', 'ForBiggerFun.mp4', 60, 41200, 192),
    (0, 'Designing a clean UI with Material 3', 'Education', 'ForBiggerJoyrides.mp4', 15, 97600, 288),
    (1, 'Indie game soundtrack: the making of', 'Music', 'ForBiggerMeltdowns.mp4', 15, 18700, 480),
    (2, 'Cooperative puzzle games worth playing', 'Gaming', 'SubaruOutbackOnStreetAndDirt.mp4', 594, 64100, 840),
    (4, 'Marathon training: the first four weeks', 'Sports', 'WeAreGoingOnBullrun.mp4', 47, 12900, 1440),
    (6, 'Short film: the last bus home', 'Entertainment', 'WhatCarCanYouGetForAGrand.mp4', 521, 230000, 9600),
  ];

  /// Returns the number of videos added (0 when the data already exists).
  Future<int> run({required String ownerId}) async {
    final marker = _db.collection('meta').doc('seed');
    if ((await marker.get()).exists) return 0;

    final store = ChannelStore(_db);
    final channelIds = <String>[];
    final channelNames = <String>[];
    for (final name in _channelNames) {
      final existing = await store.findIdByName(name);
      final id = existing ?? (await store.create(ownerId: ownerId, name: name, isDefault: false)).id;
      channelIds.add(id);
      channelNames.add(name);
    }

    final now = DateTime.now();
    final batch = _db.batch();
    for (final v in _videos) {
      final ref = _db.collection('videos').doc();
      batch.set(ref, {
        'ownerId': ownerId,
        'channelId': channelIds[v.$1],
        'channelName': channelNames[v.$1],
        'title': v.$2,
        'description': '',
        'categoryName': v.$3,
        'videoUrl': '$_base${v.$4}',
        'durationSec': v.$5,
        'viewCount': v.$6,
        'likeCount': 0,
        'commentCount': 0,
        'visibility': 'public',
        'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: v.$7))),
      });
    }
    batch.set(marker, {'seededBy': ownerId, 'at': FieldValue.serverTimestamp()});
    await batch.commit();
    return _videos.length;
  }
}
