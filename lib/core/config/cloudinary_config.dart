/// Cloudinary settings for video and image upload (see CLOUDINARY_SETUP.md).
///
/// Either edit the default values below, or pass them when running:
///   flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
///
/// The upload preset must be *unsigned*, so no secret is stored in the app.
abstract final class CloudinaryConfig {
  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'YOUR_CLOUD_NAME',
  );

  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'YOUR_UNSIGNED_PRESET',
  );

  static bool get isConfigured =>
      !cloudName.startsWith('YOUR_') && !uploadPreset.startsWith('YOUR_');
}
