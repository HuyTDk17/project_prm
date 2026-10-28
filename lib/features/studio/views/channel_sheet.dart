import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/context_ext.dart';
import '../../../shared/widgets/channel_avatar.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import 'create_channel_sheet.dart';

/// Lists the channels of the account, lets the user switch the active one
/// or create another channel.
Future<void> showChannelSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => _ChannelSheet(
      onCreate: () {
        Navigator.of(sheetContext).pop();
        showCreateChannelSheet(context);
      },
      onSwitched: (name) {
        Navigator.of(sheetContext).pop();
        context.showSnack('Now using "$name"');
      },
    ),
  );
}

class _ChannelSheet extends StatelessWidget {
  const _ChannelSheet({required this.onCreate, required this.onSwitched});

  final VoidCallback onCreate;
  final ValueChanged<String> onSwitched;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final auth = context.watch<AuthViewModel>();
    final active = auth.activeChannel;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text('Your channels', style: theme.textTheme.headlineSmall),
            ),
            if (auth.channels.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  'You do not have a channel yet. Create one to start uploading videos.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            for (final channel in auth.channels)
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: ChannelAvatar(name: channel.name, size: 40),
                title: Text(channel.name, style: theme.textTheme.titleMedium),
                subtitle: channel.id == active?.id ? const Text('Active channel') : null,
                trailing: channel.id == active?.id
                    ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                    : null,
                onTap: () {
                  context.read<AuthViewModel>().switchChannel(channel.id);
                  onSwitched(channel.name);
                },
              ),
            const Divider(height: 24),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(Icons.add_rounded, color: scheme.primary),
              ),
              title: Text('Create a new channel', style: theme.textTheme.titleMedium),
              onTap: onCreate,
            ),
          ],
        ),
      ),
    );
  }
}
