import 'package:flutter/material.dart';

/// Small pill: Public (green) or Private (amber).
class VisibilityBadge extends StatelessWidget {
  const VisibilityBadge({super.key, required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final color = isPublic ? const Color(0xFF2E7D32) : const Color(0xFFB26A00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPublic ? Icons.public_rounded : Icons.lock_outline_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
