import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/doctor_notification_service.dart';

class DoctorNotificationsScreen extends StatefulWidget {
  final DoctorNotificationService notificationService;

  const DoctorNotificationsScreen({
    super.key,
    required this.notificationService,
  });

  @override
  State<DoctorNotificationsScreen> createState() => _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifs = await widget.notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load clinical notifications. Please retry.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markRead(NotificationModel notif) async {
    if (notif.isRead) return;
    try {
      await widget.notificationService.markAsRead(notif.id);
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notif.id);
        if (idx != -1) {
          _notifications[idx] = NotificationModel(
            id: notif.id,
            userId: notif.userId,
            title: notif.title,
            message: notif.message,
            type: notif.type,
            isRead: true,
            metadata: notif.metadata,
            createdAt: notif.createdAt,
          );
        }
      });
    } catch (_) {
      // Continue silently
    }
  }

  Future<void> _markAllRead() async {
    try {
      await widget.notificationService.markAllAsRead();
      setState(() {
        _notifications = _notifications
            .map((n) => NotificationModel(
                  id: n.id,
                  userId: n.userId,
                  title: n.title,
                  message: n.message,
                  type: n.type,
                  isRead: true,
                  metadata: n.metadata,
                  createdAt: n.createdAt,
                ))
            .toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark all as read.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Clinical Notifications & Alerts'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _notifications.any((n) => !n.isRead) ? _markAllRead : null,
            child: const Text('Mark all read'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none, size: 54, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No notifications at this time.',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'System updates and appointment requests will appear here.',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final notif = _notifications[i];
                          return InkWell(
                            onTap: () => _markRead(notif),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: notif.isRead ? AppColors.borderHairline : const Color(0xFF86EFAC),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    notif.isRead ? Icons.notifications_none : Icons.notifications_active,
                                    color: notif.isRead ? AppColors.textMuted : AppColors.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notif.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                            color: AppColors.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif.message,
                                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${notif.createdAt.toLocal().day}/${notif.createdAt.toLocal().month} ${notif.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${notif.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
