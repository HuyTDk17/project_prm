enum NotificationType {
  newVideo,
  newComment,
  newSubscriber;

  static NotificationType fromName(String? name) {
    switch (name) {
      case 'NEW_COMMENT':
        return NotificationType.newComment;
      case 'NEW_SUBSCRIBER':
        return NotificationType.newSubscriber;
      default:
        return NotificationType.newVideo;
    }
  }
}

/// A notification of the current user (BR14).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.videoId,
    this.channelId,
  });

  final String id;
  final NotificationType type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? videoId;
  final String? channelId;
}
