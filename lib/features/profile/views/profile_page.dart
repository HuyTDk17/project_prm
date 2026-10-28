import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/account_badge.dart';
import '../../../shared/widgets/channel_avatar.dart';
import '../../../core/utils/context_ext.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../dev/firestore_seeder.dart';
import '../../studio/views/channel_sheet.dart';

/// Minimal profile tab: who is logged in, their channels, and Log out.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _seed(BuildContext context, String ownerId) async {
    try {
      final added = await FirestoreSeeder().run(ownerId: ownerId);
      if (!context.mounted) return;
      context.showSnack(added == 0
          ? 'Demo data already exists.'
          : 'Added $added demo videos. Refresh Home to see them.');
    } catch (e) {
      if (!context.mounted) return;
      context.showSnack('Seeding failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = context.watch<AuthViewModel>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();
    final active = auth.activeChannel;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ChannelAvatar(name: user.displayName, size: 96),
                const SizedBox(height: 16),
                Text(user.displayName, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                AccountBadge(channelCount: user.channels.length),
                if (active != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Active channel: ${active.name}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => showChannelSheet(context),
                    icon: const Icon(Icons.switch_account_rounded),
                    label: Text(user.hasChannel ? 'Your channels' : 'Create a channel'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _seed(context, user.id),
                      icon: const Icon(Icons.dataset_outlined),
                      label: const Text('Seed demo videos (dev only)'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<AuthViewModel>().logout(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
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
