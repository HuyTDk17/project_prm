import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/user_role.dart';

/// Small pill showing the role of a user. Only the manager gets the lumen colour.
class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final manager = role.canManageChannel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: manager ? AppColors.lumen : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            manager ? Icons.movie_creation_rounded : Icons.visibility_rounded,
            size: 14,
            color: manager ? AppColors.ink : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            role.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: manager ? AppColors.ink : scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
