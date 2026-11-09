import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final NotificationService notificationService;

  const NotificationsScreen({
    super.key,
    required this.notificationService,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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
      final list = await widget.notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load notifications';
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
          _notifications[idx] = notif.copyWith(isRead: true);
        }
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await widget.notificationService.markAllAsRead();
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: AppColors.primaryTeal)),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadNotifications, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.notifications_none, size: 48, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'No notifications',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Updates about appointments and consultations appear here.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: AppColors.primaryTeal,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            final timeStr =
                                '${notif.createdAt.toLocal().day}/${notif.createdAt.toLocal().month} ${notif.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${notif.createdAt.toLocal().minute.toString().padLeft(2, '0')}';

                            return GestureDetector(
                              onTap: () => _markRead(notif),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: notif.isRead ? AppColors.cardBorder : const Color(0xFFBBF7D0),
                                  ),
                                  boxShadow: AppColors.cardShadow,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      notif.isRead ? Icons.notifications_none : Icons.notifications_active,
                                      size: 20,
                                      color: notif.isRead ? const Color(0xFF64748B) : AppColors.primaryTeal,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  notif.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                timeStr,
                                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif.message,
                                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
