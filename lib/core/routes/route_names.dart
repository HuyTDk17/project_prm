abstract final class RouteNames {
  /// Home is public: guests can browse and watch without an account.
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const upload = '/upload';
  static const search = '/search';
  static const studioVideos = '/studio/videos';
  static const studioEditPattern = '/studio/videos/:id';
  static String studioEdit(String id) => '/studio/videos/$id';
  static const studioComments = '/studio/comments';
  static const studioSettings = '/studio/settings';
  static const channelPattern = '/channel/:id';
  static String channel(String id) => '/channel/$id';
  static const videoPattern = '/video/:id';
  static String video(String id) => '/video/$id';
}
