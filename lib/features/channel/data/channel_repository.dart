import '../../../shared/models/video.dart';

/// Public information of a channel.
class ChannelInfo {
  const ChannelInfo({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.subscriberCount,
    this.avatarUrl,
    this.bannerUrl,
  });

  final String id;
  final String ownerId;
  final String name;
  final String description;
  final int subscriberCount;
  final String? avatarUrl;
  final String? bannerUrl;
}

abstract class ChannelRepository {
  Future<ChannelInfo?> getChannel(String id);

  /// Public videos of the channel, newest first.
  Future<List<Video>> getVideos(String channelId);
}

class MockChannelRepository implements ChannelRepository {
  @override
  Future<ChannelInfo?> getChannel(String id) async => null;

  @override
  Future<List<Video>> getVideos(String channelId) async => const [];
}
