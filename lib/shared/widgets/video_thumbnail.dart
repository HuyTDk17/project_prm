import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../models/video.dart';

/// 16:9 thumbnail. Draws a jewel-tone gradient until real images exist.
class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({super.key, required this.video, this.hovered = false});

  final Video video;

  /// True while a mouse pointer is over the card (desktop / web).
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.thumbGradients[video.colorSeed % AppColors.thumbGradients.length];

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),
          CustomPaint(painter: _GlowPainter(seed: video.colorSeed)),
          // The gradient stays visible while the image loads or if it fails.
          if (video.thumbnailPath != null && video.thumbnailPath!.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                video.thumbnailPath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => const SizedBox.shrink(),
              ),
            ),
          Center(
            child: AnimatedScale(
              scale: hovered ? 1.12 : 1,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: hovered ? 0.55 : 0.32),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                Formatters.duration(video.durationSec),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft light blobs so every thumbnail looks a little different.
class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed * 7919);
    for (var i = 0; i < 3; i++) {
      final center = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final radius = size.shortestSide * (0.35 + rnd.nextDouble() * 0.45);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: 0.18), Colors.white.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) => oldDelegate.seed != seed;
}
