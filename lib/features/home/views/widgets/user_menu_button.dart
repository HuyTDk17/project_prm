import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/routes/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/account_badge.dart';
import '../../../../shared/widgets/channel_avatar.dart';
import '../../../auth/viewmodels/auth_viewmodel.dart';
import '../../../studio/views/channel_sheet.dart';

enum _MenuAction { channels, logout }

/// Top-right account entry: a "Log in" button for guests, an avatar with the
/// account menu for logged-in users.
class UserMenuButton extends StatelessWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;

    if (user == null) {
      final wide = context.screenWidth >= 720;
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: wide
            ? FilledButton.tonalIcon(
                key: const Key('appbar_login'),
                onPressed: () => context.push(RouteNames.login),
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('Log in'),
              )
            : IconButton(
                key: const Key('appbar_login'),
                tooltip: 'Log in',
                onPressed: () => context.push(RouteNames.login),
                icon: const Icon(Icons.account_circle_outlined, size: 28),
              ),
      );
    }

    final active = auth.activeChannel;
    final theme = Theme.of(context);

    return PopupMenuButton<_MenuAction>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      onSelected: (action) {
        switch (action) {
          case _MenuAction.channels:
            showChannelSheet(context);
          case _MenuAction.logout:
            context.read<AuthViewModel>().logout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_MenuAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName, style: theme.textTheme.titleMedium),
              Text(
                user.email,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              AccountBadge(channelCount: user.channels.length),
              if (active != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Active: ${active.name}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_MenuAction>(
          value: _MenuAction.channels,
          child: Row(
            children: [
              Icon(Icons.switch_account_rounded, size: 20),
              SizedBox(width: 12),
              Text('Your channels'),
            ],
          ),
        ),
        const PopupMenuItem<_MenuAction>(
          value: _MenuAction.logout,
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20),
              SizedBox(width: 12),
              Text('Log out'),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ChannelAvatar(name: user.displayName, size: 36),
      ),
    );
  }
}
