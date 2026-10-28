import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/app_notification.dart';
import '../../../shared/widgets/state_views.dart';
import '../viewmodels/notification_viewmodel.dart';

/// Notifications tab (BR14): new videos, comments and subscribers.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationViewModel>();
    final theme = Theme.of(context);

    Widget content;
    if (vm.isLoading && vm.items.isEmpty) {
      content = const Center(child: CircularProgressIndicator());
    } else if (vm.error != null && vm.items.isEmpty) {
      content = StateView(
        icon: Icons.wifi_off_rounded,
        title: AppStrings.genericError,
        message: 'We could not load your notifications.',
        actionLabel: 'Try again',
        onAction: vm.refresh,
      );
    } else if (vm.items.isEmpty) {
      content = const StateView(
        icon: Icons.notifications_none_rounded,
        title: AppStrings.noNotifications,
        message: 'New videos from your subscriptions and activity on your videos will show up here.',
      );
    } else {
      content = RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: vm.items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) => _NotificationTile(item: vm.items[index]),
        ),
      );
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(child: Text('Notifications', style: theme.textTheme.headlineSmall)),
                    TextButton(
                      onPressed: vm.unread == 0 ? null : vm.markAllRead,
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final AppNotification item;

  IconData get _icon {
    switch (item.type) {
      case NotificationType.newVideo:
        return Icons.play_circle_outline_rounded;
      case NotificationType.newComment:
        return Icons.chat_bubble_outline_rounded;
      case NotificationType.newSubscriber:
        return Icons.person_add_alt_1_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: item.isRead ? Colors.transparent : scheme.primary.withValues(alpha: 0.07),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Icon(_icon, color: scheme.primary),
        ),
        title: Text(
          item.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700),
        ),
        subtitle: Text(Formatters.timeAgo(item.createdAt)),
        trailing: item.isRead ? null : Icon(Icons.circle, size: 10, color: scheme.primary),
        onTap: () {
          context.read<NotificationViewModel>().markRead(item);
          final videoId = item.videoId;
          final channelId = item.channelId;
          if (videoId != null) {
            context.push(RouteNames.video(videoId));
          } else if (channelId != null) {
            context.push(RouteNames.channel(channelId));
          }
        },
      ),
    );
  }
}
