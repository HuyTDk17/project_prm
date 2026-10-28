import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../models/video.dart';
import 'channel_avatar.dart';
import 'shimmer.dart';
import 'video_thumbnail.dart';

/// Video entry of the feed: thumbnail on top, details below.
class VideoCard extends StatefulWidget {
  const VideoCard({super.key, required this.video, this.onTap, this.onChannelTap});

  final Video video;
  final VoidCallback? onTap;
  final VoidCallback? onChannelTap;

  /// Height of everything under the thumbnail at text scale 1.0.
  /// Used by the grid to compute a fixed row height.
  static const double detailsHeight = 112;

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final video = widget.video;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Semantics(
        button: true,
        label: '${video.title}, ${video.channelName}',
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: VideoThumbnail(video: video, hovered: _hovered),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: widget.onChannelTap,
                    child: ChannelAvatar(name: video.channelName, size: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(height: 1.25),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video.channelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.compactCount(video.viewCount),
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                Formatters.timeAgo(video.createdAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading placeholder with the same proportions as [VideoCard].
class VideoCardSkeleton extends StatelessWidget {
  const VideoCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: SkeletonBox(radius: 18),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 40, height: 40, circle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(width: 160, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 110, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
