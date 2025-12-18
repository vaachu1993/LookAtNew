import 'package:flutter/material.dart';
import '../../models/notification_item.dart';
import '../../widgets/common_bottom_nav_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Sample notification data
  final List<NotificationItem> notifications = [
    // Today notifications
    NotificationItem(
      id: '1',
      type: NotificationType.newsPublished,
      avatarUrl: 'https://logo.clearbit.com/cnn.com',
      title: 'CNN News published a new story',
      time: '09:30 AM',
      timestamp: DateTime.now(),
      thumbnailUrl:
          'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=200',
    ),
    NotificationItem(
      id: '2',
      type: NotificationType.follow,
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      title: 'Mike Out started following you',
      time: '09:30 AM',
      timestamp: DateTime.now(),
      followStatus: FollowStatus.notFollowing,
    ),
    NotificationItem(
      id: '3',
      type: NotificationType.follow,
      avatarUrl: 'https://i.pravatar.cc/150?img=45',
      title: 'Yura Yumla started following you',
      time: '09:30 AM',
      timestamp: DateTime.now(),
      followStatus: FollowStatus.following,
    ),
    NotificationItem(
      id: '4',
      type: NotificationType.newsPublished,
      avatarUrl: 'https://logo.clearbit.com/cnbc.com',
      title: 'CNBC News published a new story',
      time: '09:30 AM',
      timestamp: DateTime.now(),
      thumbnailUrl:
          'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=200',
    ),
    // Yesterday notifications
    NotificationItem(
      id: '5',
      type: NotificationType.follow,
      avatarUrl: 'https://i.pravatar.cc/150?img=33',
      title: 'Yara Yumla started following you',
      time: '09:30 AM',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      followStatus: FollowStatus.following,
    ),
    NotificationItem(
      id: '6',
      type: NotificationType.newsPublished,
      avatarUrl: 'https://logo.clearbit.com/cnbc.com',
      title: 'CNBC News published a new story',
      time: '09:30 AM',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      thumbnailUrl:
          'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=200',
    ),
    NotificationItem(
      id: '7',
      type: NotificationType.newsPublished,
      avatarUrl: 'https://logo.clearbit.com/cnn.com',
      title: 'CNN News published a new story',
      time: '09:30 AM',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      thumbnailUrl:
          'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=200',
    ),
  ];

  // Track follow status changes
  Map<String, FollowStatus> followStatusMap = {};

  @override
  void initState() {
    super.initState();
    // Initialize follow status map
    for (var notification in notifications) {
      if (notification.followStatus != null) {
        followStatusMap[notification.id] = notification.followStatus!;
      }
    }
  }

  void _toggleFollowStatus(String notificationId) {
    setState(() {
      final currentStatus = followStatusMap[notificationId];
      if (currentStatus == FollowStatus.notFollowing) {
        followStatusMap[notificationId] = FollowStatus.following;
      } else {
        followStatusMap[notificationId] = FollowStatus.notFollowing;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group notifications by time
    final todayNotifications = notifications.where((n) => n.isToday).toList();
    final yesterdayNotifications = notifications
        .where((n) => n.isYesterday)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Today section
          if (todayNotifications.isNotEmpty) ...[
            _buildSectionHeader('Today'),
            ...todayNotifications.map(
              (notification) => _buildNotificationItem(notification),
            ),
          ],
          // Yesterday section
          if (yesterdayNotifications.isNotEmpty) ...[
            _buildSectionHeader('Yesterday'),
            ...yesterdayNotifications.map(
              (notification) => _buildNotificationItem(notification),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const CommonBottomNavBar(
        currentIndex: 3, // Notifications tab active
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
            child: ClipOval(
              child: Image.network(
                notification.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: notification.type == NotificationType.newsPublished
                        ? Colors.blue.shade700
                        : Colors.grey.shade400,
                    child: Icon(
                      notification.type == NotificationType.newsPublished
                          ? Icons.article
                          : Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.time,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right side: thumbnail or follow button
          if (notification.type == NotificationType.newsPublished)
            _buildThumbnail(notification.thumbnailUrl!)
          else
            _buildFollowButton(notification),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String thumbnailUrl) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.image, color: Colors.grey, size: 28),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFollowButton(NotificationItem notification) {
    final status =
        followStatusMap[notification.id] ?? FollowStatus.notFollowing;
    final isFollowing = status == FollowStatus.following;

    return GestureDetector(
      onTap: () => _toggleFollowStatus(notification.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.white : const Color(0xFFE20035),
          borderRadius: BorderRadius.circular(20),
          border: isFollowing
              ? Border.all(color: Colors.grey.shade300, width: 1)
              : null,
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow back',
          style: TextStyle(
            color: isFollowing ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
