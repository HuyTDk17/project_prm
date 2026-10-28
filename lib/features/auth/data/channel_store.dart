import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/models/channel.dart';
import 'auth_repository.dart';

/// Creates and reads channels in Firestore.
///
/// A channel name must be unique (BR04). Firestore has no unique index, so the
/// name is reserved by a document `channelNames/{lower-case name}` that is
/// created in the same transaction as the channel.
class ChannelStore {
  ChannelStore(this._db);

  final FirebaseFirestore _db;

  static const maxChannelsPerAccount = 5;

  /// Document id that reserves a channel name (case-insensitive).
  static String keyFor(String name) => Uri.encodeComponent(name.trim().toLowerCase());

  Future<Channel> create({
    required String ownerId,
    required String name,
    required bool isDefault,
  }) async {
    final trimmed = name.trim();
    final nameRef = _db.collection('channelNames').doc(keyFor(trimmed));
    final channelRef = _db.collection('channels').doc();
    await _db.runTransaction((tx) async {
      final taken = await tx.get(nameRef);
      if (taken.exists) throw const ChannelException(AppStrings.channelNameTaken);
      tx.set(nameRef, {'channelId': channelRef.id, 'ownerId': ownerId});
      tx.set(channelRef, {
        'ownerId': ownerId,
        'name': trimmed,
        'isDefault': isDefault,
        'subscriberCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    return Channel(id: channelRef.id, ownerId: ownerId, name: trimmed, isDefault: isDefault);
  }

  /// Default channel = display name; a number is added while the name is taken.
  Future<Channel> createDefault({required String ownerId, required String displayName}) async {
    final base = displayName.trim().length >= 3 ? displayName.trim() : '${displayName.trim()} channel';
    for (var n = 1; n <= 30; n++) {
      final candidate = n == 1 ? base : '$base $n';
      try {
        return await create(ownerId: ownerId, name: candidate, isDefault: true);
      } on ChannelException {
        continue;
      }
    }
    throw const ChannelException(AppStrings.channelNameTaken);
  }

  Future<List<Channel>> listByOwner(String ownerId) async {
    final snap = await _db.collection('channels').where('ownerId', isEqualTo: ownerId).get();
    final channels = snap.docs.map((doc) {
      final m = doc.data();
      return Channel(
        id: doc.id,
        ownerId: ownerId,
        name: (m['name'] as String?) ?? '',
        description: m['description'] as String?,
        isDefault: (m['isDefault'] as bool?) ?? false,
      );
    }).toList();
    // Default channel first, then by name (no composite index needed).
    channels.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return channels;
  }

  /// Id of the channel that reserved [name], or null.
  Future<String?> findIdByName(String name) async {
    final doc = await _db.collection('channelNames').doc(keyFor(name)).get();
    return doc.data()?['channelId'] as String?;
  }
}
