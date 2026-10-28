import '../../../core/constants/app_strings.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/channel.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class ChannelException implements Exception {
  const ChannelException(this.message);
  final String message;
}

/// Source of accounts and their channels. The mock below is replaced by SQLite later.
abstract class AuthRepository {
  /// Returns the user of a saved session, or null for a guest (BR17).
  Future<AppUser?> restoreSession();

  Future<AppUser> login(String email, String password);

  /// Logs in with a Google account. The first time it also creates the account
  /// and its default channel, like a registration (BR03).
  Future<AppUser> loginWithGoogle();

  Future<void> logout();

  /// Creates the account and its default channel (named after the display
  /// name) in one step, so the user can upload right away (BR03).
  Future<AppUser> register(String displayName, String email, String password);

  /// Creates an additional channel owned by [owner]. Throws [ChannelException]
  /// when the name is invalid or already used (BR04).
  Future<Channel> createChannel(AppUser owner, String name);
}

/// In-memory accounts for the UI phase.
class MockAuthRepository implements AuthRepository {
  static const demoPassword = 'Pass@123';
  static const singleChannelEmail = 'viewer1@minitube.com';
  static const multiChannelEmail = 'manager1@minitube.com';

  static const _seedUsers = <String, AppUser>{
    // One account, one default channel.
    singleChannelEmail: AppUser(
      id: 'u2',
      email: singleChannelEmail,
      displayName: 'Nguyen B',
      channels: [Channel(id: 'c3', ownerId: 'u2', name: 'Nguyen B', isDefault: true)],
    ),
    // One account, two channels: shows the channel switcher.
    multiChannelEmail: AppUser(
      id: 'u1',
      email: multiChannelEmail,
      displayName: 'Tran Code',
      channels: [
        Channel(id: 'c1', ownerId: 'u1', name: 'Code Academy', isDefault: true),
        Channel(id: 'c2', ownerId: 'u1', name: 'Pixel Lab'),
      ],
    ),
  };

  final Set<String> _takenNames = {
    'code academy',
    'pixel lab',
    'nguyen b',
    'dev simple',
    'music hub',
    'track notes',
    'tech brief',
    'night shift',
  };

  // Accounts registered while the app is running.
  final Map<String, AppUser> _registered = {};
  final Map<String, String> _passwords = {};

  // Extra channels created while the app is running, kept per user id.
  final Map<String, List<Channel>> _created = {};
  int _nextUserId = 100;
  int _nextChannelId = 100;

  @override
  Future<AppUser?> restoreSession() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<AppUser> loginWithGoogle() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _seedUsers[singleChannelEmail]!;
  }

  @override
  Future<AppUser> login(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final key = email.trim().toLowerCase();
    final seed = _seedUsers[key];
    final user = seed ?? _registered[key];
    final expected = seed != null ? demoPassword : _passwords[key];
    if (user == null || password != expected) {
      throw const AuthException(AppStrings.invalidCredentials);
    }
    final extra = _created[user.id] ?? const <Channel>[];
    return extra.isEmpty ? user : user.copyWith(channels: [...user.channels, ...extra]);
  }

  @override
  Future<AppUser> register(String displayName, String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final key = email.trim().toLowerCase();
    if (_seedUsers.containsKey(key) || _registered.containsKey(key)) {
      throw const AuthException(AppStrings.emailTaken);
    }
    final name = displayName.trim();
    final userId = 'u${_nextUserId++}';
    final channel = Channel(id: 'c${_nextChannelId++}', ownerId: userId, name: _uniqueChannelName(name), isDefault: true);
    final user = AppUser(id: userId, email: key, displayName: name, channels: [channel]);
    _registered[key] = user;
    _passwords[key] = password;
    return user;
  }

  /// Default channel name = display name; a number is added when it is taken.
  String _uniqueChannelName(String displayName) {
    final base = displayName.length >= 3 ? displayName : '$displayName channel';
    var candidate = base;
    var n = 2;
    while (!_takenNames.add(candidate.toLowerCase())) {
      candidate = '$base $n';
      n++;
    }
    return candidate;
  }

  @override
  Future<Channel> createChannel(AppUser owner, String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final trimmed = name.trim();
    if (trimmed.length < 3 || trimmed.length > 50) {
      throw const ChannelException(AppStrings.channelNameInvalid);
    }
    if (owner.channels.length >= 5) {
      throw const ChannelException(AppStrings.maxChannels);
    }
    if (!_takenNames.add(trimmed.toLowerCase())) {
      throw const ChannelException(AppStrings.channelNameTaken);
    }
    final channel = Channel(id: 'c${_nextChannelId++}', ownerId: owner.id, name: trimmed);
    (_created[owner.id] ??= []).add(channel);
    return channel;
  }
}
