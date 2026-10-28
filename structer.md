project_prm393/
├── assets/
│   ├── images/
│   └── icons/
├── test/
└── lib/
    ├── main.dart
    ├── app.dart                        # MaterialApp, theme, router, MultiProvider
    │
    ├── core/                           # Dùng chung toàn app
    │   ├── constants/                  # app_colors.dart, 
    │   ├── theme/                      # app_theme.dart
    │   ├── routes/                     # app_router.dart (guard theo role)
    │   ├── services/                   # api_client.dart, 
    │   └── utils/                      # validators.dart, 
    │
    ├── shared/                         # Dùng chung nhiều feature
    │   ├── models/                     # user.dart, video.dart, channel.dart, user_role.dart
    │   └── widgets/                    # app_button.dart, video_card.dart, loading_view.dart
    │
    └── features/
        ├── auth/                       # Đăng nhập, đăng ký, xác định role
        │   ├── data/                   # auth_repository.dart
        │   ├── viewmodels/             # auth_viewmodel.dart
        │   └── views/                  # login_screen.dart, register_screen.dart
        │
        ├── home/                       # [Viewer] Feed video, tìm kiếm
        │   ├── data/                   # video_repository.dart
        │   ├── viewmodels/             # home_viewmodel.dart
        │   └── views/                  # home_screen.dart, search_screen.dart
        │
        ├── video_player/               # [Viewer] Xem video, like, bình luận
        │   ├── data/                   # comment_model.dart, comment_repository.dart
        │   ├── viewmodels/             # player_viewmodel.dart
        │   └── views/                  # player_screen.dart, widgets/comment_list.dart
        │
        ├── channel/                    # [Viewer] Trang kênh, đăng ký (subscribe)
        │   ├── data/                   # channel_repository.dart
        │   ├── viewmodels/             # channel_viewmodel.dart
        │   └── views/                  # channel_screen.dart
        │
        ├── library/                    # [Viewer] Lịch sử, video đã thích, kênh đã đăng ký
        │   ├── data/
        │   ├── viewmodels/
        │   └── views/
        │
        └── studio/                     # [Quản lý kênh] Toàn bộ chức năng quản lý
            ├── data/                   # studio_repository.dart
            ├── viewmodels/             # dashboard_viewmodel.dart, upload_viewmodel.dart, 
            └── views/
                ├── dashboard_screen.dart       # Thống kê tổng quan
                ├── manage_videos_screen.dart   # Danh sách video của kênh
                ├── upload_video_screen.dart    # Đăng video mới
                ├── edit_video_screen.dart      # Sửa/xóa video
                ├── channel_settings_screen.dart# Sửa thông tin kênh
                └── widgets/