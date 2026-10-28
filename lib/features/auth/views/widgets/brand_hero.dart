import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/video.dart';
import '../../../../shared/widgets/brand_logo.dart';
import '../../../../shared/widgets/video_thumbnail.dart';

const _inkGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.ink, AppColors.inkSoft],
);

/// Left side of the wide login layout: logo, a fan of video cards, tagline.
class BrandPanel extends StatelessWidget {
  const BrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(gradient: _inkGradient),
      child: Stack(
        children: [
          // A soft signal glow behind the cards.
          Positioned(
            left: -120,
            bottom: -160,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.signal.withValues(alpha: 0.28),
                    AppColors.signal.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandLogo(size: 44, onDark: true),
                  const Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(width: 440, height: 320, child: VideoFan()),
                      ),
                    ),
                  ),
                  Text(
                    'Watch what you love.\nPublish what you make.',
                    style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Text(
                      'Follow channels, keep your own library and run a channel from one place.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
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

/// Header of the narrow auth layout. [trailing] is placed at the top right.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final theme = Theme.of(context);
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24, top + 28, 24, 32),
          decoration: const BoxDecoration(
            gradient: _inkGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(size: 40, onDark: true),
              const SizedBox(height: 28),
              Text(
                'Watch what you love.\nPublish what you make.',
                style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, height: 1.2),
              ),
            ],
          ),
        ),
        if (trailing != null) Positioned(top: top + 4, right: 8, child: trailing!),
      ],
    );
  }
}

/// Three overlapping video cards that fan out once when the screen opens.
/// This is the only intro motion of the app; it is skipped with "reduce motion".
class VideoFan extends StatelessWidget {
  const VideoFan({super.key});

  static final _samples = [
    Video(id: '1', title: '', channelName: '', categoryName: '', durationSec: 754, viewCount: 0, createdAt: DateTime(2024)),
    Video(id: '3', title: '', channelName: '', categoryName: '', durationSec: 1320, viewCount: 0, createdAt: DateTime(2024)),
    Video(id: '0', title: '', channelName: '', categoryName: '', durationSec: 1830, viewCount: 0, createdAt: DateTime(2024)),
  ];

  // left, top, angle (radians) of each card when fully opened.
  static const _targets = [
    (left: 0.0, top: 150.0, angle: -0.12),
    (left: 170.0, top: 10.0, angle: 0.09),
    (left: 80.0, top: 80.0, angle: -0.02),
  ];

  static const double _cardWidth = 270;
  static const double _startLeft = 85;
  static const double _startTop = 85;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < _samples.length; i++)
              Positioned(
                left: _startLeft + (_targets[i].left - _startLeft) * t,
                top: _startTop + (_targets[i].top - _startTop) * t,
                width: _cardWidth,
                child: Transform.rotate(
                  angle: _targets[i].angle * t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: VideoThumbnail(video: _samples[i]),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
