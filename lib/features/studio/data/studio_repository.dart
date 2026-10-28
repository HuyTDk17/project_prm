import '../../../shared/models/comment.dart';
import '../../../shared/models/video.dart';

/// A comment together with the video it was written on (moderation list).
class ModerationComment {
  const ModerationComment({required this.comment, required this.videoId, required this.videoTitle});

  final Comment comment;
  final String videoId;
  final String videoTitle;
}

/// What the owner of a channel does with the channel and its videos (BR18).
abstract class StudioRepository {
  /// All videos of the channel, public and private.
  Future<List<Video>> getChannelVideos({required String ownerId, required String channelId});

  /// Saves the edited details. Becoming Public for the first time notifies
  /// the subscribers (BR08).
  Future<void> updateVideo(
    Video video, {
    required String title,
    required String description,
    required String category,
    required bool isPublic,
    String? thumbnailUrl,
  });

  /// BR15: deletes the video with its comments and likes.
  Future<void> deleteVideo(Video video);

  /// Latest comments on the given videos, newest first.
  Future<List<ModerationComment>> getComments(List<Video> videos);

  /// BR04: renames with a unique name; also updates the channel name shown on its videos.
  Future<void> updateChannel({
    required String channelId,
    required String ownerId,
    required String oldName,
    required String name,
    required String description,
    String? avatarUrl,
    String? bannerUrl,
  });
}

/// Empty implementation for tests.
class MockStudioRepository implements StudioRepository {
  @override
  Future<List<Video>> getChannelVideos({required String ownerId, required String channelId}) async => const [];
  @override
  Future<void> updateVideo(Video video,
      {required String title,
      required String description,
      required String category,
      required bool isPublic,
      String? thumbnailUrl}) async {}
  @override
  Future<void> deleteVideo(Video video) async {}
  @override
  Future<List<ModerationComment>> getComments(List<Video> videos) async => const [];
  @override
  Future<void> updateChannel(
      {required String channelId,
      required String ownerId,
      required String oldName,
      required String name,
      required String description,
      String? avatarUrl,
      String? bannerUrl}) async {}
}
