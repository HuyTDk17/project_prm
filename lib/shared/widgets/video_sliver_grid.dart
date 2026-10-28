import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';
import 'video_card.dart';

/// Computes how many columns fit and builds the matching sliver.
class VideoSliverGrid extends StatelessWidget {
  const VideoSliverGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  static const double _maxContentWidth = 1440;
  static const double _minCardWidth = 300;
  static const double _gap = 20;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;

        final side = width > _maxContentWidth + 48
            ? (width - _maxContentWidth) / 2
            : (width < Responsive.compactMax ? 16.0 : 24.0);
        final content = width - side * 2;

        final columns = width < Responsive.compactMax
            ? 1
            : (content / _minCardWidth).floor().clamp(2, 5);

        final padding = EdgeInsets.fromLTRB(side, 8, side, 32);

        if (columns == 1) {
          return SliverPadding(
            padding: padding,
            sliver: SliverList.separated(
              itemCount: itemCount,
              itemBuilder: itemBuilder,
              separatorBuilder: (context, index) => const SizedBox(height: 24),
            ),
          );
        }

        final itemWidth = (content - _gap * (columns - 1)) / columns;
        final itemHeight = itemWidth * 9 / 16 + VideoCard.detailsHeight * textScale;

        return SliverPadding(
          padding: padding,
          sliver: SliverGrid.builder(
            itemCount: itemCount,
            itemBuilder: itemBuilder,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: _gap,
              mainAxisSpacing: 28,
              mainAxisExtent: itemHeight,
            ),
          ),
        );
      },
    );
  }
}
