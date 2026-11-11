import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WellnessDashboardScreen extends StatefulWidget {
  const WellnessDashboardScreen({super.key});

  @override
  State<WellnessDashboardScreen> createState() => _WellnessDashboardScreenState();
}

class _WellnessDashboardScreenState extends State<WellnessDashboardScreen> {
  int _waterGlasses = 5;
  final int _waterGoal = 8;
  double _sleepHours = 7.5;
  final int _steps = 6420;
  final int _stepGoal = 10000;

  void _addWater() {
    if (_waterGlasses < 15) {
      setState(() => _waterGlasses++);
    }
  }

  void _removeWater() {
    if (_waterGlasses > 0) {
      setState(() => _waterGlasses--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waterPercent = (_waterGlasses / _waterGoal).clamp(0.0, 1.0);
    final stepPercent = (_steps / _stepGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Personal Wellness Tracking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Water Intake Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.water_drop_rounded, color: Color(0xFF0284C7), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Daily Hydration',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          '$_waterGlasses / $_waterGoal Glasses',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: waterPercent,
                      backgroundColor: const Color(0xFFE0F2FE),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFE0F2FE),
                            foregroundColor: const Color(0xFF0284C7),
                          ),
                          icon: const Icon(Icons.remove),
                          onPressed: _removeWater,
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            Text(
                              '${(_waterGlasses * 250)} ml',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const Text(
                              'Target: 2,000 ml',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add),
                          onPressed: _addWater,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Sleep Tracking Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bedtime_rounded, color: Color(0xFF7C3AED), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Restorative Sleep',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Optimal',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_sleepHours.toStringAsFixed(1)} Hours',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF7C3AED)),
                              onPressed: () {
                                if (_sleepHours > 2.0) {
                                  setState(() => _sleepHours -= 0.5);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF7C3AED)),
                              onPressed: () {
                                if (_sleepHours < 14.0) {
                                  setState(() => _sleepHours += 0.5);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Text(
                      'Deep Sleep: 2h 15m • Light Sleep: 4h 30m • REM: 45m',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Step & Physical Activity Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.directions_walk_rounded, color: Color(0xFF16A34A), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Physical Activity',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        Text(
                          '$_steps / $_stepGoal Steps',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: stepPercent,
                      backgroundColor: const Color(0xFFDCFCE7),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricColumn('Distance', '${(_steps * 0.0008).toStringAsFixed(1)} km'),
                        _buildMetricColumn('Calories', '${(_steps * 0.04).toInt()} kcal'),
                        _buildMetricColumn('Active Time', '${(_steps / 100).toInt()} min'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
