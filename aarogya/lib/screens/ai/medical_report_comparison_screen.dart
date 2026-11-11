import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MedicalReportComparisonScreen extends StatefulWidget {
  const MedicalReportComparisonScreen({super.key});

  @override
  State<MedicalReportComparisonScreen> createState() => _MedicalReportComparisonScreenState();
}

class _MedicalReportComparisonScreenState extends State<MedicalReportComparisonScreen> {
  final String _selectedReportA = 'Lipid & Metabolic Panel (15 Aug 2026)';
  final String _selectedReportB = 'Recent Follow-up Panel (28 Oct 2026)';

  final List<Map<String, dynamic>> _comparisonMetrics = [
    {
      'testName': 'Fasting Blood Glucose',
      'unit': 'mg/dL',
      'standardRange': '70 - 99',
      'valA': 142.0,
      'valB': 108.0,
      'isImproved': true,
      'deltaText': '-34 mg/dL (-24%)',
      'status': 'IMPROVED',
    },
    {
      'testName': 'HbA1c (Glycated Hemoglobin)',
      'unit': '%',
      'standardRange': '< 5.7',
      'valA': 7.6,
      'valB': 6.4,
      'isImproved': true,
      'deltaText': '-1.2% (Controlled)',
      'status': 'IMPROVED',
    },
    {
      'testName': 'Total Cholesterol',
      'unit': 'mg/dL',
      'standardRange': '< 200',
      'valA': 228.0,
      'valB': 185.0,
      'isImproved': true,
      'deltaText': '-43 mg/dL (Normal)',
      'status': 'NORMALIZED',
    },
    {
      'testName': 'Serum Creatinine',
      'unit': 'mg/dL',
      'standardRange': '0.7 - 1.3',
      'valA': 1.1,
      'valB': 1.0,
      'isImproved': true,
      'deltaText': '-0.1 (Optimal)',
      'status': 'STABLE',
    },
    {
      'testName': 'Hemoglobin (Hb)',
      'unit': 'g/dL',
      'standardRange': '13.5 - 17.5',
      'valA': 12.8,
      'valB': 14.1,
      'isImproved': true,
      'deltaText': '+1.3 g/dL (Restored)',
      'status': 'IMPROVED',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Lab Report Comparison',
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
              // Report Selector Card
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
                    const Text(
                      'Select Reports for Chronological Comparison',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Baseline Report (Earlier):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _selectedReportA,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward_rounded, color: AppColors.primaryTeal, size: 20),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Recent Report (Current):', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2F1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _selectedReportB,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryTeal),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Informational comparison only. Trend metrics do not constitute a medical diagnosis. Consult your doctor for therapeutic decisions.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Biomarker Chronological Delineation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),

              // Metric Cards
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _comparisonMetrics.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final metric = _comparisonMetrics[index];
                  final testName = metric['testName'] as String;
                  final unit = metric['unit'] as String;
                  final standardRange = metric['standardRange'] as String;
                  final valA = metric['valA'] as double;
                  final valB = metric['valB'] as double;
                  final isImproved = metric['isImproved'] as bool;
                  final deltaText = metric['deltaText'] as String;
                  final status = metric['status'] as String;

                  return Container(
                    padding: const EdgeInsets.all(14),
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
                            Flexible(
                              child: Text(
                                testName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isImproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: isImproved ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Normal Reference: $standardRange $unit',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Previous Value
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Previous', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$valA $unit',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Icon(Icons.trending_down_rounded, color: Color(0xFF16A34A), size: 24),
                            ),
                            // Current Value
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBBF7D0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Current', style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$valB $unit',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clinical Change: $deltaText',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isImproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
