import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';
import 'features/home/data/video_repository.dart';
import 'features/home/viewmodels/home_viewmodel.dart';
import 'core/services/cloudinary_service.dart';
import 'core/services/media_uploader.dart';
import 'features/channel/data/channel_repository.dart';
import 'features/library/viewmodels/library_viewmodel.dart';
import 'features/search/data/search_index.dart';
import 'features/studio/data/studio_repository.dart';
import 'features/studio/viewmodels/studio_viewmodel.dart';
import 'features/notification/viewmodels/notification_viewmodel.dart';
import 'features/video_player/data/engagement_repository.dart';

/// Root widget: registers repositories and the session ViewModel, then the router.
class MiniTubeApp extends StatelessWidget {
  /// Repositories can be replaced (tests use the in-memory mocks).
  const MiniTubeApp({
    super.key,
    this.authRepository,
    this.videoRepository,
    this.mediaUploader,
    this.engagementRepository,
    this.channelRepository,
    this.studioRepository,
  });

  final AuthRepository? authRepository;
  final VideoRepository? videoRepository;
  final MediaUploader? mediaUploader;
  final EngagementRepository? engagementRepository;
  final ChannelRepository? channelRepository;
  final StudioRepository? studioRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => authRepository ?? MockAuthRepository()),
        Provider<VideoRepository>(create: (_) => videoRepository ?? MockVideoRepository()),
        Provider<EngagementRepository>(create: (_) => engagementRepository ?? MockEngagementRepository()),
        Provider<StudioRepository>(create: (_) => studioRepository ?? MockStudioRepository()),
        Provider<ChannelRepository>(create: (_) => channelRepository ?? MockChannelRepository()),
        // Search keeps the public videos in memory for a minute (see SearchIndex).
        Provider<SearchIndex>(create: (ctx) => SearchIndex(ctx.read<VideoRepository>())),
        Provider<MediaUploader>(create: (_) => mediaUploader ?? CloudinaryService()),
        // The feed lives for the whole session, so the Upload page can refresh it.
        ChangeNotifierProvider<HomeViewModel>(
          create: (ctx) => HomeViewModel(ctx.read<VideoRepository>())..load(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(ctx.read<AuthRepository>()),
        ),
        // These two follow the logged-in user (they reload when the user changes).
        ChangeNotifierProvider<NotificationViewModel>(
          create: (ctx) => NotificationViewModel(ctx.read<EngagementRepository>(), ctx.read<AuthViewModel>()),
        ),
        // Videos and numbers of the active channel (Studio screens).
        ChangeNotifierProvider<StudioViewModel>(
          create: (ctx) => StudioViewModel(
            ctx.read<StudioRepository>(),
            ctx.read<ChannelRepository>(),
            ctx.read<AuthViewModel>(),
          ),
        ),
        ChangeNotifierProvider<LibraryViewModel>(
          create: (ctx) => LibraryViewModel(ctx.read<EngagementRepository>(), ctx.read<AuthViewModel>()),
        ),
      ],
      child: const _AppView(),
    );
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  late final GoRouter _router = createRouter(context.read<AuthViewModel>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      scrollBehavior: const _AppScrollBehavior(),
      routerConfig: _router,
    );
  }
}

/// Lets the mouse drag scrollable lists (category chips) on web and desktop.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
