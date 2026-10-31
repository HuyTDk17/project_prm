import 'dart:typed_data';

import '../constants/media_limits.dart';

class UploadException implements Exception {
  const UploadException(this.message);
  final String message;
}

/// Result of a video upload.
class UploadedVideo {
  const UploadedVideo({required this.url, required this.thumbnailUrl, required this.durationSec});

  /// Address the player uses to stream the video.
  final String url;

  /// Frame of the video, usable as thumbnail.
  final String thumbnailUrl;
  final int durationSec;
}

/// Where video and image files are stored. Firestore keeps only their
/// addresses. The implementation is Cloudinary; it can be replaced
/// (for example by Firebase Storage) without touching the screens.
abstract class MediaUploader {
  Future<UploadedVideo> uploadVideo({
    required Uint8List bytes,
    required String filename,
    void Function(double progress)? onProgress,
  });

  /// Shrinks the image (longest side at most [maxSide] pixels), uploads it and
  /// returns its address.
  Future<String> uploadImage({
    required Uint8List bytes,
    required String filename,
    int maxSide = MediaLimits.thumbnailSide,
  });
}
