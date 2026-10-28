import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Pill under the user name: "Viewer" until the account owns a channel,
/// then "N channel(s)" in the lumen colour.
class AccountBadge extends StatelessWidget {
  const AccountBadge({super.key, required this.channelCount});

  final int channelCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final creator = channelCount > 0;
    final label = creator ? '$channelCount channel${channelCount == 1 ? '' : 's'}' : 'Viewer';
    final fg = creator ? AppColors.ink : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: creator ? AppColors.lumen : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(creator ? Icons.movie_creation_rounded : Icons.visibility_rounded, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
          ),
        ],
      ),
    );
  }
}
