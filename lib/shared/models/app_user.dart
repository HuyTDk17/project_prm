import 'channel.dart';

/// An account. Everybody can watch; owning a channel is what lets a user
/// publish videos, so there is no role to choose at registration.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.channels = const [],
  });

  /// Firebase Auth uid.
  final String id;
  final String email;
  final String displayName;

  /// Channels owned by this account (zero or more).
  final List<Channel> channels;

  bool get hasChannel => channels.isNotEmpty;

  AppUser copyWith({List<Channel>? channels}) => AppUser(
        id: id,
        email: email,
        displayName: displayName,
        channels: channels ?? this.channels,
      );
}
