import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/comment.dart';
import '../../../shared/models/video.dart';
import '../../home/data/video_repository.dart';
import '../data/engagement_repository.dart';

/// State of the player screen: the video, likes, comments, subscription and
/// related videos. Actions that need an account are guarded by the screen
/// (login-required prompt); here [_user] is null for a guest.
class PlayerViewModel extends ChangeNotifier {
  PlayerViewModel({
    required String videoId,
    Video? initial,
    required EngagementRepository engagement,
    required VideoRepository videos,
    required AppUser? user,
  })  : _videoId = videoId,
        _video = initial,
        _engagement = engagement,
        _videos = videos,
        _user = user {
    load();
  }

  final String _videoId;
  final EngagementRepository _engagement;
  final VideoRepository _videos;
  final AppUser? _user;

  Video? _video;
  bool _loading = true;
  String? _error;
  bool _liked = false;
  int _likeCount = 0;
  bool _subscribed = false;
  int _subscriberCount = 0;
  List<Comment> _comments = const [];
  List<Video> _related = const [];
  String? _commentError;
  bool _sendingComment = false;
  bool _disposed = false;

  Video? get video => _video;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get liked => _liked;
  int get likeCount => _likeCount;
  bool get subscribed => _subscribed;
  int get subscriberCount => _subscriberCount;
  List<Comment> get comments => _comments;
  List<Video> get related => _related;
  String? get commentError => _commentError;
  bool get isSendingComment => _sendingComment;

  /// BR12: the owner cannot subscribe to the own channel.
  bool get isOwnChannel {
    final u = _user;
    final v = _video;
    if (u == null || v == null) return false;
    return v.ownerId == u.id || u.channels.any((c) => c.id == v.channelId);
  }

  Future<void> load() async {
    try {
      final fresh = await _engagement.getVideo(_videoId);
      final video = fresh ?? _video;
      if (video == null) {
        _error = AppStrings.genericError;
        _loading = false;
        notifyListeners();
        return;
      }
      _video = video;
      _likeCount = video.likeCount;
      _loading = false;
      notifyListeners();

      // BR09 / BR13: count the view, and save the history for a logged-in user.
      unawaited(_engagement.recordView(video, userId: _user?.id));
      _video = video.copyWith(viewCount: video.viewCount + 1);
      notifyListeners();

      await Future.wait([
        _loadUserState(video),
        _loadComments(),
        _loadSubscribers(video),
        _loadRelated(video),
      ]);
    } catch (_) {
      _error = AppStrings.genericError;
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserState(Video video) async {
    final u = _user;
    if (u == null) return;
    try {
      _liked = await _engagement.isLiked(u.id, video.id);
      final channelId = video.channelId;
      if (channelId != null) _subscribed = await _engagement.isSubscribed(u.id, channelId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadSubscribers(Video video) async {
    final channelId = video.channelId;
    if (channelId == null) return;
    try {
      _subscriberCount = await _engagement.subscriberCount(channelId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadComments() async {
    try {
      _comments = await _engagement.getComments(_videoId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadRelated(Video video) async {
    try {
      var list = await _videos.getPublicVideos(category: video.categoryName);
      list = list.where((v) => v.id != video.id).toList();
      if (list.length < 4) {
        final all = await _videos.getPublicVideos();
        final ids = list.map((v) => v.id).toSet();
        list = [...list, ...all.where((v) => v.id != video.id && !ids.contains(v.id))];
      }
      _related = list.take(12).toList();
      notifyListeners();
    } catch (_) {}
  }

  /// BR10: like / unlike with an optimistic update.
  Future<void> toggleLike() async {
    final u = _user;
    final v = _video;
    if (u == null || v == null) return;
    final target = !_liked;
    _liked = target;
    _likeCount += target ? 1 : -1;
    notifyListeners();
    try {
      await _engagement.setLiked(userId: u.id, video: v, liked: target);
    } catch (_) {
      _liked = !target;
      _likeCount += target ? -1 : 1;
      notifyListeners();
    }
  }

  /// BR12: subscribe / unsubscribe with an optimistic update.
  Future<void> toggleSubscribe() async {
    final u = _user;
    final v = _video;
    if (u == null || v == null || v.channelId == null || isOwnChannel) return;
    final target = !_subscribed;
    _subscribed = target;
    _subscriberCount += target ? 1 : -1;
    notifyListeners();
    try {
      await _engagement.setSubscribed(
        user: u,
        channelId: v.channelId!,
        channelName: v.channelName,
        ownerId: v.ownerId,
        subscribe: target,
      );
    } catch (_) {
      _subscribed = !target;
      _subscriberCount += target ? -1 : 1;
      notifyListeners();
    }
  }

  /// BR11: 1-500 characters, not blank. Returns true when the comment was saved.
  Future<bool> addComment(String text) async {
    final u = _user;
    final v = _video;
    if (u == null || v == null) return false;
    final clean = text.trim();
    if (clean.isEmpty) return _commentFail(AppStrings.commentEmpty);
    if (clean.length > 500) return _commentFail(AppStrings.commentTooLong);
    _sendingComment = true;
    _commentError = null;
    notifyListeners();
    try {
      final comment = await _engagement.addComment(video: v, user: u, text: clean);
      _comments = [comment, ..._comments];
      _video = v.copyWith(commentCount: v.commentCount + 1);
      return true;
    } catch (_) {
      return _commentFail(AppStrings.genericError);
    } finally {
      _sendingComment = false;
      notifyListeners();
    }
  }

  bool _commentFail(String message) {
    _commentError = message;
    notifyListeners();
    return false;
  }

  void clearCommentError() {
    if (_commentError == null) return;
    _commentError = null;
    notifyListeners();
  }

  /// BR11: the author or the owner of the video can delete a comment.
  bool canDelete(Comment c) => _user != null && (c.authorId == _user.id || _video?.ownerId == _user.id);

  Future<void> deleteComment(Comment comment) async {
    final v = _video;
    if (v == null) return;
    final before = _comments;
    _comments = _comments.where((c) => c.id != comment.id).toList();
    _video = v.copyWith(commentCount: (v.commentCount - 1).clamp(0, 1 << 30));
    notifyListeners();
    try {
      await _engagement.deleteComment(videoId: v.id, commentId: comment.id);
    } catch (_) {
      _comments = before;
      _video = v;
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
