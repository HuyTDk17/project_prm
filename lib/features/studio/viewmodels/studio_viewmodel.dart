import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/models/video.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../channel/data/channel_repository.dart';
import '../data/studio_repository.dart';

/// Videos and numbers of the active channel, shared by the Studio screens.
/// It follows the session: it reloads when the user or the active channel changes.
class StudioViewModel extends ChangeNotifier {
  StudioViewModel(this._repository, this._channels, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final StudioRepository _repository;
  final ChannelRepository _channels;
  final AuthViewModel _auth;

  String? _channelId;
  List<Video> _videos = const [];
  ChannelInfo? _info;
  bool _loading = false;
  String? _error;
  bool _disposed = false;

  List<Video> get videos => _videos;
  ChannelInfo? get info => _info;
  bool get isLoading => _loading;
  String? get error => _error;

  int get videoCount => _videos.length;
  int get totalViews => _videos.fold(0, (sum, v) => sum + v.viewCount);
  int get totalLikes => _videos.fold(0, (sum, v) => sum + v.likeCount);
  int get totalComments => _videos.fold(0, (sum, v) => sum + v.commentCount);
  int get subscribers => _info?.subscriberCount ?? 0;

  Video? videoById(String id) => _videos.where((v) => v.id == id).firstOrNull;

  void _onAuthChanged() {
    final id = _auth.activeChannel?.id;
    if (id == _channelId) return;
    _channelId = id;
    _videos = const [];
    _info = null;
    _error = null;
    notifyListeners();
    if (id != null) refresh();
  }

  Future<void> refresh() async {
    final user = _auth.user;
    final channel = _auth.activeChannel;
    if (user == null || channel == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getChannelVideos(ownerId: user.id, channelId: channel.id),
        _channels.getChannel(channel.id),
      ]);
      if (_channelId == channel.id) {
        _videos = results[0] as List<Video>;
        _info = results[1] as ChannelInfo?;
      }
    } catch (_) {
      _error = AppStrings.genericError;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Returns null on success, or an error message.
  Future<String?> updateVideo(
    Video video, {
    required String title,
    required String description,
    required String category,
    required bool isPublic,
    String? thumbnailUrl,
  }) async {
    try {
      await _repository.updateVideo(
        video,
        title: title,
        description: description,
        category: category,
        isPublic: isPublic,
        thumbnailUrl: thumbnailUrl,
      );
      _videos = [
        for (final v in _videos)
          v.id == video.id
              ? v.copyWith(
                  title: title,
                  description: description,
                  categoryName: category,
                  isPublic: isPublic,
                  thumbnailPath: thumbnailUrl,
                )
              : v,
      ];
      notifyListeners();
      return null;
    } catch (_) {
      return AppStrings.genericError;
    }
  }

  Future<String?> deleteVideo(Video video) async {
    try {
      await _repository.deleteVideo(video);
      _videos = _videos.where((v) => v.id != video.id).toList();
      notifyListeners();
      return null;
    } catch (_) {
      return AppStrings.genericError;
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
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
