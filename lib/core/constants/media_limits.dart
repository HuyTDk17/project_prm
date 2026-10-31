/// Limits for the files a user can upload. They keep the free plan of
/// Cloudinary usable: 40 MB is also the biggest video that a free account can
/// transform (for example to make the thumbnail frame).
class MediaLimits {
  const MediaLimits._();

  /// BR06: maximum size of a video file.
  static const maxVideoBytes = 40 * 1024 * 1024;

  /// BR06: maximum size of an image file the user may pick (thumbnail, avatar,
  /// banner). The image is shrunk again before it is uploaded.
  static const maxImageBytes = 5 * 1024 * 1024;

  /// Longest side, in pixels, of the image that is uploaded.
  static const thumbnailSide = 1280;
  static const avatarSide = 512;
  static const bannerSide = 1600;
}
