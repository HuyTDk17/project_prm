import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/viewmodels/auth_viewmodel.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/channel/views/channel_page.dart';
import '../../features/search/views/search_page.dart';
import '../../features/studio/views/channel_settings_screen.dart';
import '../../features/studio/views/comment_moderation_screen.dart';
import '../../features/studio/views/edit_video_screen.dart';
import '../../features/studio/views/manage_videos_screen.dart';
import '../../features/studio/views/upload_screen.dart';
import '../../features/video_player/views/player_screen.dart';
import '../../shared/models/video.dart';
import 'route_names.dart';

/// The app opens on Home for everybody (guests included).
/// Login and Register are pushed on top of Home when an action needs an
/// account. Once the user is logged in these two pages redirect back to Home.
GoRouter createRouter(AuthViewModel auth) {
  return GoRouter(
    initialLocation: RouteNames.home,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthPage = location == RouteNames.login || location == RouteNames.register;
      if (auth.isAuthenticated && isAuthPage) return RouteNames.home;
      // Guests cannot open the upload page or any Studio page (BR05).
      if (!auth.isAuthenticated && (location == RouteNames.upload || location.startsWith('/studio'))) {
        return RouteNames.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.home,
        pageBuilder: (context, state) => _fade(state, const HomeScreen()),
      ),
      GoRoute(
        path: RouteNames.search,
        pageBuilder: (context, state) =>
            _fade(state, SearchPage(initialQuery: state.uri.queryParameters['q'] ?? '')),
      ),
      GoRoute(
        path: RouteNames.channelPattern,
        pageBuilder: (context, state) => _fade(state, ChannelPage(channelId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: RouteNames.videoPattern,
        pageBuilder: (context, state) {
          final extra = state.extra;
          return _fade(
            state,
            PlayerScreen(videoId: state.pathParameters['id']!, initial: extra is Video ? extra : null),
          );
        },
      ),
      GoRoute(
        path: RouteNames.studioVideos,
        pageBuilder: (context, state) => _fade(state, const ManageVideosScreen()),
      ),
      GoRoute(
        path: RouteNames.studioEditPattern,
        pageBuilder: (context, state) {
          final extra = state.extra;
          return _fade(
            state,
            EditVideoScreen(videoId: state.pathParameters['id']!, initial: extra is Video ? extra : null),
          );
        },
      ),
      GoRoute(
        path: RouteNames.studioComments,
        pageBuilder: (context, state) => _fade(state, const CommentModerationScreen()),
      ),
      GoRoute(
        path: RouteNames.studioSettings,
        pageBuilder: (context, state) => _fade(state, const ChannelSettingsScreen()),
      ),
      GoRoute(
        path: RouteNames.upload,
        pageBuilder: (context, state) => _fade(state, const UploadScreen()),
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) => _fade(state, const LoginScreen()),
      ),
      GoRoute(
        path: RouteNames.register,
        pageBuilder: (context, state) => _fade(state, const RegisterScreen()),
      ),
    ],
  );
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}
