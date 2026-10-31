# project_prm393

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
Yêu cầu: Flutter SDK, Chrome.

1. flutter pub get
2. flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=<cloud name> --dart-define=CLOUDINARY_UPLOAD_PRESET=<preset>
   (nếu thấy lỗi "debug connection": flutter run -d web-server --web-port 5000
    rồi mở http://localhost:5000)
3. Đăng ký tài khoản trong app (hoặc Continue with Google).
4. Tab Profile -> "Seed demo videos" (chỉ hiện ở chế độ debug) để nạp dữ liệu mẫu.

Không cần đăng nhập Firebase CLI để chạy. App dùng sẵn dự án Firebase trong
lib/firebase_options.dart. Muốn dùng Firebase riêng: xem FIREBASE_SETUP.md.