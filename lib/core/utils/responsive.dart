import 'package:flutter/widgets.dart';

/// Window size classes (follows the Material 3 window size classes).
enum ScreenSize { compact, medium, expanded }

abstract final class Responsive {
  /// Below this width the layout is a single column with a bottom bar.
  static const double compactMax = 600;

  /// Below this width the layout is a grid with two or three columns.
  static const double mediumMax = 1024;

  /// Width from which the bottom bar is replaced by a navigation rail.
  static const double railMin = 800;

  /// Width from which the navigation rail shows its labels next to the icons.
  static const double railExtendedMin = 1200;

  static ScreenSize fromWidth(double width) {
    if (width < compactMax) return ScreenSize.compact;
    if (width < mediumMax) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  ScreenSize get screenSize => Responsive.fromWidth(screenWidth);
}
