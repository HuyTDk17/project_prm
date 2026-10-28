import 'package:flutter/material.dart';

/// Brand palette of MiniTube.
///
/// Ink + Signal: a deep blue-black stage with a single hot "signal" accent.
/// Lumen (warm yellow) is reserved for the Channel Manager role only.
abstract final class AppColors {
  static const ink = Color(0xFF11132A);
  static const inkSoft = Color(0xFF1C1F3D);
  static const signal = Color(0xFFF23D4F);
  static const signalDeep = Color(0xFFC81E3A);
  static const lumen = Color(0xFFFFC857);
  static const mist = Color(0xFFF3F4FA);
  static const mistDeep = Color(0xFFE8EAF4);
  static const slate = Color(0xFF6B7088);
  static const line = Color(0xFFE3E5F0);

  /// Jewel-tone gradients used for video thumbnails (until real images exist).
  static const thumbGradients = <List<Color>>[
    [Color(0xFF2B2D6E), Color(0xFFF0506E)],
    [Color(0xFF0B4F6C), Color(0xFF5ED6B5)],
    [Color(0xFF4A1942), Color(0xFFFFA45B)],
    [Color(0xFF16213E), Color(0xFF4EA8DE)],
    [Color(0xFF12372A), Color(0xFFADC178)],
    [Color(0xFF5B1A3A), Color(0xFFE76F8B)],
  ];
}
