import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/channel.dart';
import '../data/auth_repository.dart';

/// Holds the session (who is logged in), the channels of the account and
/// which channel is currently active.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repository) {
    restore();
  }

  final AuthRepository _repository;

  AppUser? _user;
  String? _activeChannelId;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasChannel => _user?.hasChannel ?? false;
  List<Channel> get channels => _user?.channels ?? const [];

  /// The channel used for uploads and Studio; null when the account has none.
  Channel? get activeChannel {
    final list = channels;
    if (list.isEmpty) return null;
    return list.firstWhere((c) => c.id == _activeChannelId, orElse: () => list.first);
  }

  /// Restores the saved session at app start so the user stays logged in (BR17).
  Future<void> restore() async {
    try {
      final user = await _repository.restoreSession();
      if (user == null) return;
      _user = user;
      _activeChannelId = user.channels.isEmpty ? null : user.channels.first.id;
      notifyListeners();
    } catch (_) {
      // No saved session or no network: continue as a guest.
    }
  }

  /// Returns true on success. The router reacts to the change of [user].
  Future<bool> login(String email, String password) =>
      _authenticate(() => _repository.login(email, password));

  /// Logs in with Google (creates the account and default channel the first time).
  Future<bool> loginWithGoogle() => _authenticate(() => _repository.loginWithGoogle());

  /// Creates the account (with its default channel) and logs the user in.
  Future<bool> register(String displayName, String email, String password) =>
      _authenticate(() => _repository.register(displayName, email, password));

  Future<bool> _authenticate(Future<AppUser> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final user = await action();
      _user = user;
      _activeChannelId = user.channels.isEmpty ? null : user.channels.first.id;
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e, st) {
      // Keep the real reason visible while developing (permission-denied,
      // missing database, network...), instead of hiding it.
      debugPrint('Auth failed: $e\n$st');
      _errorMessage = kDebugMode
          ? '${AppStrings.genericError}\n($e)'
          : AppStrings.genericError;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a channel and makes it the active one.
  /// Returns an error message, or null when it worked.
  Future<String?> createChannel(String name) async {
    final current = _user;
    if (current == null) return AppStrings.genericError;
    try {
      final channel = await _repository.createChannel(current, name);
      _user = current.copyWith(channels: [...current.channels, channel]);
      _activeChannelId = channel.id;
      notifyListeners();
      return null;
    } on ChannelException catch (e) {
      return e.message;
    } catch (_) {
      return AppStrings.genericError;
    }
  }

  /// Replaces a channel after it was edited (name, description, images).
  void updateChannel(Channel channel) {
    final current = _user;
    if (current == null) return;
    _user = current.copyWith(
      channels: [for (final c in current.channels) c.id == channel.id ? channel : c],
    );
    notifyListeners();
  }

  void switchChannel(String channelId) {
    if (!channels.any((c) => c.id == channelId)) return;
    _activeChannelId = channelId;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _activeChannelId = null;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.logout();
    } catch (_) {
      // The local state is already cleared.
    }
  }
}
