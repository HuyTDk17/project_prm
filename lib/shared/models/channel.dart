/// A channel. One account can own several channels (like on YouTube).
/// [id] is the Firestore document id.
class Channel {
  const Channel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.isDefault = false,
  });

  final String id;
  final String ownerId;
  final String name;
  final String? description;

  /// True for the channel created automatically at registration (BR03).
  final bool isDefault;
}
