import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';

/// App mark (rounded square with a play glyph) and optional wordmark.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 36,
    this.showWordmark = true,
    this.onDark = false,
  });

  final double size;
  final bool showWordmark;

  /// Use white text when the logo sits on the dark brand surface.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final textColor = onDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.3),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.signal, AppColors.signalDeep],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.signal.withValues(alpha: 0.35),
                blurRadius: size * 0.4,
                offset: Offset(0, size * 0.12),
              ),
            ],
          ),
          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: size * 0.68),
        ),
        if (showWordmark) ...[
          SizedBox(width: size * 0.3),
          Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: size * 0.58,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: textColor,
            ),
          ),
        ],
      ],
    );
  }
}
