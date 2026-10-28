import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/models/channel.dart';
import '../../../shared/models/video.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../video_player/data/engagement_repository.dart';

/// Personal library: watch history, liked videos and subscriptions (BR10, BR12, BR13).
class LibraryViewModel extends ChangeNotifier {
  LibraryViewModel(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
  }

  final EngagementRepository _repository;
  final AuthViewModel _auth;

  String? _userId;
  List<Video> _history = const [];
  List<Video> _liked = const [];
  List<Channel> _subscriptions = const [];
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  List<Video> get history => _history;
  List<Video> get liked => _liked;
  List<Channel> get subscriptions => _subscriptions;
  bool get isLoading => _loading;
  String? get error => _error;

  void _onAuthChanged() {
    final id = _auth.user?.id;
    if (id == _userId) return;
    _userId = id;
    _history = const [];
    _liked = const [];
    _subscriptions = const [];
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    final id = _auth.user?.id;
    if (id == null) return;
    _userId = id;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getHistory(id),
        _repository.getLiked(id),
        _repository.getSubscriptions(id),
      ]);
      if (_userId == id) {
        _history = results[0] as List<Video>;
        _liked = results[1] as List<Video>;
        _subscriptions = results[2] as List<Channel>;
      }
    } catch (_) {
      _error = AppStrings.genericError;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromHistory(Video video) async {
    final id = _userId;
    if (id == null) return;
    _history = _history.where((v) => v.id != video.id).toList();
    notifyListeners();
    try {
      await _repository.removeHistory(id, video.id);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    final id = _userId;
    if (id == null) return;
    _history = const [];
    notifyListeners();
    try {
      await _repository.clearHistory(id);
    } catch (_) {}
  }

  Future<void> removeLike(Video video) async {
    final id = _userId;
    if (id == null) return;
    _liked = _liked.where((v) => v.id != video.id).toList();
    notifyListeners();
    try {
      await _repository.setLiked(userId: id, video: video, liked: false);
    } catch (_) {}
  }

  Future<void> unsubscribe(Channel channel) async {
    final user = _auth.user;
    if (user == null) return;
    _subscriptions = _subscriptions.where((c) => c.id != channel.id).toList();
    notifyListeners();
    try {
      await _repository.setSubscribed(
        user: user,
        channelId: channel.id,
        channelName: channel.name,
        ownerId: channel.ownerId,
        subscribe: false,
      );
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
