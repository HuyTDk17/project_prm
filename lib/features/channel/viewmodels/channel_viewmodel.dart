import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/video.dart';
import '../../video_player/data/engagement_repository.dart';
import '../data/channel_repository.dart';

/// State of the public channel page: info, public videos and the subscription.
class ChannelViewModel extends ChangeNotifier {
  ChannelViewModel({
    required String channelId,
    required ChannelRepository channels,
    required EngagementRepository engagement,
    required AppUser? user,
  })  : _channelId = channelId,
        _channels = channels,
        _engagement = engagement,
        _user = user {
    load();
  }

  final String _channelId;
  final ChannelRepository _channels;
  final EngagementRepository _engagement;
  final AppUser? _user;

  ChannelInfo? _info;
  List<Video> _videos = const [];
  bool _loading = true;
  String? _error;
  bool _subscribed = false;
  int _subscriberCount = 0;
  bool _disposed = false;

  ChannelInfo? get info => _info;
  List<Video> get videos => _videos;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get subscribed => _subscribed;
  int get subscriberCount => _subscriberCount;

  /// BR12: no subscribe button on a channel of the same account.
  bool get isOwn {
    final u = _user;
    final i = _info;
    return u != null && i != null && (i.ownerId == u.id || u.channels.any((c) => c.id == i.id));
  }

  Future<void> load() async {
    try {
      final info = await _channels.getChannel(_channelId);
      if (info == null) {
        _error = AppStrings.genericError;
        return;
      }
      _info = info;
      _subscriberCount = info.subscriberCount;
      _videos = await _channels.getVideos(_channelId);
      final u = _user;
      if (u != null) _subscribed = await _engagement.isSubscribed(u.id, _channelId);
    } catch (_) {
      _error = AppStrings.genericError;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> toggleSubscribe() async {
    final u = _user;
    final i = _info;
    if (u == null || i == null || isOwn) return;
    final target = !_subscribed;
    _subscribed = target;
    _subscriberCount += target ? 1 : -1;
    notifyListeners();
    try {
      await _engagement.setSubscribed(
        user: u,
        channelId: i.id,
        channelName: i.name,
        ownerId: i.ownerId,
        subscribe: target,
      );
    } catch (_) {
      _subscribed = !target;
      _subscriberCount += target ? -1 : 1;
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
