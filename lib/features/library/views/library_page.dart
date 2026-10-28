import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/channel.dart';
import '../../../shared/models/video.dart';
import '../../../shared/widgets/channel_avatar.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/video_thumbnail.dart';
import '../viewmodels/library_viewmodel.dart';

/// Library tab: watch history, liked videos and subscriptions.
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  Future<void> _confirmClear(BuildContext context, LibraryViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all watch history?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) vm.clearHistory();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LibraryViewModel>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Library', style: theme.textTheme.headlineSmall),
                  ),
                ),
                const TabBar(
                  tabs: [Tab(text: 'History'), Tab(text: 'Liked'), Tab(text: 'Subscriptions')],
                ),
                Expanded(
                  child: vm.isLoading && vm.history.isEmpty && vm.liked.isEmpty && vm.subscriptions.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          children: [
                            _VideoList(
                              videos: vm.history,
                              emptyIcon: Icons.history_rounded,
                              emptyTitle: AppStrings.historyEmpty,
                              emptyMessage: 'Videos you watch will appear here.',
                              menuLabel: 'Remove from history',
                              onRemove: vm.removeFromHistory,
                              onRefresh: vm.refresh,
                              header: vm.history.isEmpty
                                  ? null
                                  : Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => _confirmClear(context, vm),
                                        child: const Text('Clear all history'),
                                      ),
                                    ),
                            ),
                            _VideoList(
                              videos: vm.liked,
                              emptyIcon: Icons.thumb_up_outlined,
                              emptyTitle: AppStrings.noVideos,
                              emptyMessage: 'Videos you like will appear here.',
                              menuLabel: 'Remove like',
                              onRemove: vm.removeLike,
                              onRefresh: vm.refresh,
                            ),
                            _ChannelList(
                              channels: vm.subscriptions,
                              onUnsubscribe: vm.unsubscribe,
                              onRefresh: vm.refresh,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoList extends StatelessWidget {
  const _VideoList({
    required this.videos,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.menuLabel,
    required this.onRemove,
    required this.onRefresh,
    this.header,
  });

  final List<Video> videos;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final String menuLabel;
  final ValueChanged<Video> onRemove;
  final Future<void> Function() onRefresh;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return StateView(icon: emptyIcon, title: emptyTitle, message: emptyMessage);
    }
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
        children: [
          if (header != null) header!,
          for (final v in videos)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push(RouteNames.video(v.id), extra: v),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 168,
                      child: ClipRRect(borderRadius: BorderRadius.circular(12), child: VideoThumbnail(video: v)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            v.channelName,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            '${Formatters.compactCount(v.viewCount)} views',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<int>(
                      tooltip: 'More',
                      onSelected: (_) => onRemove(v),
                      itemBuilder: (context) => [PopupMenuItem(value: 1, child: Text(menuLabel))],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChannelList extends StatelessWidget {
  const _ChannelList({required this.channels, required this.onUnsubscribe, required this.onRefresh});

  final List<Channel> channels;
  final ValueChanged<Channel> onUnsubscribe;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const StateView(
        icon: Icons.subscriptions_outlined,
        title: AppStrings.noVideos,
        message: 'Channels you subscribe to will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        children: [
          for (final c in channels)
            ListTile(
              leading: ChannelAvatar(name: c.name, size: 44),
              title: Text(c.name, style: Theme.of(context).textTheme.titleMedium),
              onTap: () => context.push(RouteNames.channel(c.id)),
              trailing: OutlinedButton(onPressed: () => onUnsubscribe(c), child: const Text('Subscribed')),
            ),
        ],
      ),
    );
  }
}
