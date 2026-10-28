import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/models/app_notification.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../video_player/data/engagement_repository.dart';

/// Notifications of the logged-in user (BR14). It follows the session: the
/// list is cleared on logout and loaded again for the next user.
class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final EngagementRepository _repository;
  final AuthViewModel _auth;

  String? _userId;
  List<AppNotification> _items = const [];
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  List<AppNotification> get items => _items;
  bool get isLoading => _loading;
  String? get error => _error;
  int get unread => _items.where((n) => !n.isRead).length;

  void _onAuthChanged() {
    final id = _auth.user?.id;
    if (id == _userId) return;
    _userId = id;
    _items = const [];
    _error = null;
    notifyListeners();
    if (id != null) refresh();
  }

  Future<void> refresh() async {
    final id = _userId;
    if (id == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _repository.getNotifications(id);
      if (_userId == id) _items = list;
    } catch (_) {
      _error = AppStrings.genericError;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Marks one notification as read (when the user opens it).
  Future<void> markRead(AppNotification n) async {
    final id = _userId;
    if (id == null || n.isRead) return;
    _items = [
      for (final x in _items)
        if (x.id == n.id)
          AppNotification(
            id: x.id,
            type: x.type,
            message: x.message,
            isRead: true,
            createdAt: x.createdAt,
            videoId: x.videoId,
            channelId: x.channelId,
          )
        else
          x,
    ];
    notifyListeners();
    try {
      await _repository.markNotificationRead(id, n.id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final id = _userId;
    if (id == null || unread == 0) return;
    _items = [
      for (final x in _items)
        AppNotification(
          id: x.id,
          type: x.type,
          message: x.message,
          isRead: true,
          createdAt: x.createdAt,
          videoId: x.videoId,
          channelId: x.channelId,
        ),
    ];
    notifyListeners();
    try {
      await _repository.markAllNotificationsRead(id);
    } catch (_) {}
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
