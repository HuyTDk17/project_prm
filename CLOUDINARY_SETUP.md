# Cloudinary setup (video and image files, free plan, no credit card)

Firestore stores the video record; the video file itself goes to Cloudinary.

1. Register at https://cloudinary.com (free plan). On the **Dashboard** copy your **Cloud name**.
2. Open **Settings > Upload > Upload presets > Add upload preset**:
   - **Signing mode: Unsigned**
   - Folder (optional): `minitube`
   - Save, then copy the **preset name**.
3. Put both values in the app. Either edit the defaults in
   `lib/core/config/cloudinary_config.dart`, or run:
   ```
   flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud --dart-define=CLOUDINARY_UPLOAD_PRESET=your_preset
   ```
4. Add the file picker package once: `flutter pub add file_selector`
   (`dio` is already in pubspec.yaml).
5. Log in, press **+** (or Studio > Upload), choose a video up to 100 MB, fill the form and press Upload.

Notes
- The free plan limits a video to 100 MB and has a monthly usage allowance; check the limits on
  your Cloudinary dashboard.
- An unsigned preset lets anybody who knows its name upload to your account. That is fine for a
  course demo; for a real product use signed uploads from a server.
- The thumbnail is a frame of the video (Cloudinary builds it from the video address), unless you
  choose your own image.
