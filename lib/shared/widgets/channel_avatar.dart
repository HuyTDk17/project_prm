import 'package:flutter/material.dart';

/// Round avatar: the image when there is one, otherwise the first letter of
/// the name on a stable colour.
class ChannelAvatar extends StatelessWidget {
  const ChannelAvatar({super.key, required this.name, this.size = 36, this.imageUrl});

  final String name;
  final double size;
  final String? imageUrl;

  static const _colors = [
    Color(0xFF5B5FE0),
    Color(0xFF1B9AAA),
    Color(0xFFE76F51),
    Color(0xFF8E5BD6),
    Color(0xFF2A9D8F),
    Color(0xFFD6457A),
  ];

  Widget _letter() {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    final color = _colors[name.hashCode.abs() % _colors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Text(
        letter,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.42),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) return _letter();
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _letter(),
      ),
    );
  }
}
