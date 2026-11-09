import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../models/patient_profile_model.dart';

class AbhaCardWidget extends StatelessWidget {
  final PatientProfileModel profile;

  const AbhaCardWidget({super.key, required this.profile});

  String get _formattedAbhaId {
    final raw = (profile.abhaId ?? '12-3456-7890-1234').replaceAll('-', '');
    if (raw.length >= 14) {
      return '${raw.substring(0, 2)}-${raw.substring(2, 6)}-${raw.substring(6, 10)}-${raw.substring(10, 14)}';
    }
    return profile.abhaId ?? '12-3456-7890-1234';
  }

  String get _abhaAddress {
    final nameClean = profile.fullName.toLowerCase().replaceAll(' ', '.');
    return '$nameClean@abdm';
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: _formattedAbhaId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ABHA ID copied: $_formattedAbhaId'),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF003D38),
            Color(0xFF005B52),
            Color(0xFF0F766E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003D38).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Guilloche Wave Watermark
          Positioned(
            right: -40,
            bottom: -40,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: NHA Emblem & ABDM Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.local_hospital_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'National Health Authority',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Government of India • ABDM',
                                  style: TextStyle(
                                    color: Color(0xFF99F6E4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ABHA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Middle: Chip & Profile Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Smart Chip Graphic
                    Container(
                      width: 44,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEAB308), Color(0xFFCA8A04)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFEF08A), width: 1),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 10,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 1, color: Colors.black26),
                          ),
                          Positioned(
                            right: 10,
                            top: 0,
                            bottom: 0,
                            child: Container(width: 1, color: Colors.black26),
                          ),
                          Positioned(
                            top: 16,
                            left: 0,
                            right: 0,
                            child: Container(height: 1, color: Colors.black26),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Wi-Fi NFC Waves icon
                    Transform.rotate(
                      angle: 1.5708,
                      child: const Icon(
                        Icons.wifi_rounded,
                        color: Color(0xFF99F6E4),
                        size: 20,
                      ),
                    ),
                    const Spacer(),

                    // QR Code preview container
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 34,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Patient Demographics
                Text(
                  profile.fullName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Gender: ${profile.gender ?? "Male"}',
                      style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 11),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Blood: ${profile.bloodGroup ?? "O+"}',
                      style: const TextStyle(
                        color: Color(0xFFCCFBF1),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (profile.age != null) ...[
                      const SizedBox(width: 12),
                      Text(
                        'Age: ${profile.age} yrs',
                        style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // ABHA Number & Copy Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ABHA NUMBER',
                              style: TextStyle(
                                color: Color(0xFF99F6E4),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formattedAbhaId,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _copyToClipboard(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.copy_rounded, size: 13, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // ABHA Address
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'ABHA Address: $_abhaAddress',
                        style: const TextStyle(
                          color: Color(0xFF99F6E4),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 12, color: Color(0xFF34D399)),
                        SizedBox(width: 3),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

