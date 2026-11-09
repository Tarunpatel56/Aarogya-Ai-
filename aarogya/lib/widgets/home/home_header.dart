import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/patient_profile_model.dart';
import '../../models/user_model.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../services/notification_service.dart';

class HomeHeader extends StatelessWidget {
  final UserModel? user;
  final PatientProfileModel? profile;
  final AnimationController syncAnimController;
  final VoidCallback onTriggerSync;
  final NotificationService? notificationService;

  const HomeHeader({
    super.key,
    required this.user,
    required this.profile,
    required this.syncAnimController,
    required this.onTriggerSync,
    this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = profile?.fullName ?? user?.email ?? 'Patient';
    final abhaId = profile?.abhaId != null && profile!.abhaId!.isNotEmpty
        ? profile!.abhaId!
        : 'ABHA: Verified Profile';

    final initials = displayName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar circle with initials
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryTeal, width: 1.5),
            color: AppColors.mintBg,
          ),
          child: Center(
            child: Text(
              initials.isNotEmpty ? initials : 'P',
              style: const TextStyle(
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // User info & ABHA ID
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ABHA',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                abhaId,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Notification Bell
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotificationsScreen(
                  notificationService: notificationService ?? NotificationService(),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 10),

        // Refresh/Sync icon
        RotationTransition(
          turns: syncAnimController,
          child: IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.primaryTeal, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Sync EHR',
            onPressed: onTriggerSync,
          ),
        ),
      ],
    );
  }
}
