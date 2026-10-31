import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// An image ready to be uploaded.
class CompressedImage {
  const CompressedImage(this.bytes, this.filename);

  final Uint8List bytes;
  final String filename;
}

/// Makes images smaller before they are uploaded, so the free Cloudinary plan
/// lasts longer: the image is resized (longest side at most `maxSide`, never
/// enlarged) and saved again as JPEG. Images with transparent pixels stay PNG.
///
/// If anything goes wrong, or the new file is not smaller, the original file
/// is returned unchanged, so an upload never fails because of compression.
class ImageCompressor {
  const ImageCompressor._();

  static const jpegQuality = 82;

  static CompressedImage compress(Uint8List bytes, String filename, {required int maxSide}) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return CompressedImage(bytes, filename);

      var image = img.bakeOrientation(decoded);
      final landscape = image.width >= image.height;
      final longer = landscape ? image.width : image.height;
      var resized = false;
      if (longer > maxSide) {
        image = landscape
            ? img.copyResize(image, width: maxSide, interpolation: img.Interpolation.average)
            : img.copyResize(image, height: maxSide, interpolation: img.Interpolation.average);
        resized = true;
      }

      final asPng = _hasTransparency(image);
      final Uint8List out = asPng ? img.encodePng(image) : img.encodeJpg(image, quality: jpegQuality);

      // Re-encoding a small file can make it bigger: keep the original then.
      if (!resized && out.length >= bytes.length) return CompressedImage(bytes, filename);
      return CompressedImage(out, _withExtension(filename, asPng ? 'png' : 'jpg'));
    } catch (_) {
      return CompressedImage(bytes, filename);
    }
  }

  static bool _hasTransparency(img.Image image) {
    if (!image.hasAlpha) return false;
    for (final pixel in image) {
      if (pixel.a < 255) return true;
    }
    return false;
  }

  static String _withExtension(String filename, String extension) {
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;
    return '$base.$extension';
  }
}
