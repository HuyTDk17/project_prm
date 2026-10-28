import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/video.dart';
import '../../../shared/widgets/channel_avatar.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/video_thumbnail.dart';
import '../../../shared/widgets/visibility_badge.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../viewmodels/studio_viewmodel.dart';
import 'channel_sheet.dart';
import 'create_channel_sheet.dart';
import 'upload_entry.dart';

/// Studio dashboard (UC16): numbers of the active channel, shortcuts and the
/// latest videos. Without a channel it invites the user to create one.
class StudioPage extends StatelessWidget {
  const StudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final channel = auth.activeChannel;

    if (channel == null) {
      return SafeArea(
        child: StateView(
          icon: Icons.movie_creation_outlined,
          title: 'Create your channel',
          message: 'Publish videos and build an audience. One account can have several channels.',
          actionLabel: 'Create channel',
          onAction: () => showCreateChannelSheet(context),
        ),
      );
    }

    final studio = context.watch<StudioViewModel>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: studio.refresh,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Row(
                  children: [
                    ChannelAvatar(name: channel.name, size: 56, imageUrl: studio.info?.avatarUrl),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Studio', style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                          Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineSmall),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => showChannelSheet(context),
                      icon: const Icon(Icons.switch_account_rounded),
                      label: Text(auth.channels.length > 1 ? 'Switch' : 'Channels'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 640 ? 4 : 2;
                    final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
                    final cards = [
                      _StatCard(icon: Icons.visibility_outlined, label: 'Total views', value: studio.totalViews),
                      _StatCard(icon: Icons.people_outline_rounded, label: 'Subscribers', value: studio.subscribers),
                      _StatCard(icon: Icons.video_library_outlined, label: 'Videos', value: studio.videoCount),
                      _StatCard(icon: Icons.thumb_up_outlined, label: 'Likes', value: studio.totalLikes),
                    ];
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [for (final c in cards) SizedBox(width: width, child: c)],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => startUpload(context),
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Upload video'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(RouteNames.studioVideos),
                      icon: const Icon(Icons.video_settings_rounded),
                      label: const Text('Manage videos'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(RouteNames.studioComments),
                      icon: const Icon(Icons.forum_outlined),
                      label: Text('Comments (${studio.totalComments})'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(RouteNames.studioSettings),
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Channel settings'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(RouteNames.channel(channel.id)),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('View channel'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(child: Text('Latest videos', style: theme.textTheme.titleLarge)),
                    if (studio.videos.length > 3)
                      TextButton(
                        onPressed: () => context.push(RouteNames.studioVideos),
                        child: const Text('View all'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (studio.isLoading && studio.videos.isEmpty)
                  const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
                else if (studio.error != null && studio.videos.isEmpty)
                  Text(studio.error!, style: TextStyle(color: scheme.error))
                else if (studio.videos.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.video_call_outlined, size: 40, color: scheme.primary),
                        const SizedBox(height: 8),
                        Text('No videos yet', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Upload your first video to see numbers here.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                else
                  for (final v in studio.videos.take(3)) _LatestVideoRow(video: v),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(height: 10),
          Text(Formatters.compactCount(value), style: theme.textTheme.headlineMedium),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LatestVideoRow extends StatelessWidget {
  const _LatestVideoRow({required this.video});

  final Video video;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(RouteNames.studioEdit(video.id), extra: video),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: VideoThumbnail(video: video)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  VisibilityBadge(isPublic: video.isPublic),
                  const SizedBox(height: 4),
                  Text(
                    '${Formatters.compactCount(video.viewCount)} views, '
                    '${Formatters.compactCount(video.likeCount)} likes, '
                    '${Formatters.compactCount(video.commentCount)} comments',
                    style: small,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
