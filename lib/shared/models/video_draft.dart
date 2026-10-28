/// Data of a video that is being published.
class VideoDraft {
  const VideoDraft({
    required this.ownerId,
    required this.channelId,
    required this.channelName,
    required this.title,
    required this.description,
    required this.categoryName,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.durationSec,
    required this.isPublic,
  });

  final String ownerId;
  final String channelId;
  final String channelName;
  final String title;
  final String description;
  final String categoryName;
  final String videoUrl;
  final String thumbnailUrl;
  final int durationSec;
  final bool isPublic;
}
