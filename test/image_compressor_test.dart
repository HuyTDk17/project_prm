import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:project_prm393/core/utils/image_compressor.dart';

/// A PNG full of random pixels: big, and a good JPEG is much smaller.
Uint8List _noisePng(int width, int height) {
  final random = Random(1);
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(x, y, random.nextInt(256), random.nextInt(256), random.nextInt(256));
    }
  }
  return img.encodePng(image);
}

void main() {
  // UT-08: ImageCompressor shrinks big images and never breaks an upload.
  group('ImageCompressor', () {
    test('a large landscape image is resized and saved smaller as JPEG', () {
      final original = _noisePng(1800, 1200);
      final result = ImageCompressor.compress(original, 'photo.png', maxSide: 1280);
      final decoded = img.decodeImage(result.bytes)!;
      expect(decoded.width, 1280);
      expect(decoded.height, lessThan(1200));
      expect(result.bytes.length, lessThan(original.length));
      expect(result.filename, 'photo.jpg');
    });

    test('a portrait image is limited on its height', () {
      final result = ImageCompressor.compress(_noisePng(900, 1500), 'tall.png', maxSide: 1000);
      final decoded = img.decodeImage(result.bytes)!;
      expect(decoded.height, 1000);
      expect(decoded.width, lessThan(900));
    });

    test('a small image is not enlarged', () {
      final result = ImageCompressor.compress(_noisePng(200, 100), 'small.png', maxSide: 1280);
      final decoded = img.decodeImage(result.bytes)!;
      expect(decoded.width, 200);
      expect(decoded.height, 100);
    });

    test('bytes that are not an image are returned unchanged', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);
      final result = ImageCompressor.compress(bytes, 'broken.jpg', maxSide: 1280);
      expect(result.bytes, bytes);
      expect(result.filename, 'broken.jpg');
    });
  });
}
