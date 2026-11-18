import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

class PhoneLauncherUtil {
  /// Launches device phone dialer with the given phone number
  static Future<bool> launchPhone(String? phoneNumber, {BuildContext? context}) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      _showError('Phone number not available');
      return false;
    }

    // Sanitize phone number (strip whitespace, hyphens, non-standard symbols)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.isEmpty) {
      _showError('Invalid phone number format');
      return false;
    }

    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        // Fallback direct launch attempt
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showError('Could not open phone dialer: $e');
      return false;
    }
  }

  /// Launches an external official web URL
  static Future<bool> launchWeb(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  static void _showError(String message) {
    if (Get.isSnackbarOpen) return;
    Get.snackbar(
      Get.locale?.languageCode == 'hi' ? 'कॉल त्रुटि' : 'Call Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFEF4444),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}
