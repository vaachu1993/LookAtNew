import 'enums/notification_enums.dart';

export 'enums/notification_enums.dart';

class NotificationItem {
  final String id;
  final NotificationType type;
  final String avatarUrl;
  final String title;
  final String time;
  final DateTime timestamp;

  final String? thumbnailUrl;

  final FollowStatus? followStatus;

  NotificationItem({
    required this.id,
    required this.type,
    required this.avatarUrl,
    required this.title,
    required this.time,
    required this.timestamp,
    this.thumbnailUrl,
    this.followStatus,
  });

  bool get isToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return timestamp.year == yesterday.year &&
        timestamp.month == yesterday.month &&
        timestamp.day == yesterday.day;
  }
}
