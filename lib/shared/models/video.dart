class Video {
  const Video({
    required this.id,
    required this.title,
    required this.channelName,
    required this.categoryName,
    required this.durationSec,
    required this.viewCount,
    required this.createdAt,
    this.channelId,
    this.ownerId = '',
    this.description = '',
    this.likeCount = 0,
    this.commentCount = 0,
    this.isPublic = true,
    this.videoUrl,
    this.thumbnailPath,
  });

  /// Firestore document id.
  final String id;
  final String title;
  final String description;
  final String channelName;
  final String? channelId;

  /// Account that owns the channel of this video.
  final String ownerId;
  final String categoryName;
  final int durationSec;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  /// BR07: private videos are visible only to their owner.
  final bool isPublic;

  /// Address of the video file (used by the player).
  final String? videoUrl;

  /// Null until real thumbnails exist: the UI then draws a gradient.
  final String? thumbnailPath;

  /// Stable number derived from [id], used to pick the gradient of the thumbnail.
  int get colorSeed => id.codeUnits.fold(7, (hash, unit) => (hash * 31 + unit) & 0x7fffffff);

  Video copyWith({
    String? title,
    String? description,
    String? categoryName,
    bool? isPublic,
    String? thumbnailPath,
    String? channelName,
    int? viewCount,
    int? likeCount,
    int? commentCount,
  }) =>
      Video(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        channelName: channelName ?? this.channelName,
        channelId: channelId,
        ownerId: ownerId,
        categoryName: categoryName ?? this.categoryName,
        durationSec: durationSec,
        viewCount: viewCount ?? this.viewCount,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        createdAt: createdAt,
        isPublic: isPublic ?? this.isPublic,
        videoUrl: videoUrl,
        thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      );
}
