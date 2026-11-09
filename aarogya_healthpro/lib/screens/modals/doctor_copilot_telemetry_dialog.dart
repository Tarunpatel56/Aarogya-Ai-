import 'package:flutter/material.dart';
import '../../theme/clinical_sanctuary_theme.dart';
import '../../services/doctor_ai_service.dart';
import '../../models/doctor_ai_model.dart';
import '../../core/api/api_exception.dart';

class DoctorCoPilotTelemetryDialog extends StatefulWidget {
  final String patientName;
  final int age;
  final String gender;
  final String? currentDiagnosis;
  final Map<String, dynamic>? telemetry;
  final DoctorAiService? aiService;

  const DoctorCoPilotTelemetryDialog({
    super.key,
    required this.patientName,
    this.age = 45,
    this.gender = 'Male',
    this.currentDiagnosis,
    this.telemetry,
    this.aiService,
  });

  @override
  State<DoctorCoPilotTelemetryDialog> createState() => _DoctorCoPilotTelemetryDialogState();
}

class _DoctorCoPilotTelemetryDialogState extends State<DoctorCoPilotTelemetryDialog> {
  late final DoctorAiService _aiService;
  ClinicalCoPilotInsight? _insight;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? DoctorAiService();
    _loadTelemetrySummary();
  }

  Future<void> _loadTelemetrySummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _aiService.fetchCoPilotSummary(
        patientName: widget.patientName,
        age: widget.age,
        gender: widget.gender,
        currentDiagnosis: widget.currentDiagnosis ?? 'Hypertension & Cardiac Telemetry',
        telemetry: widget.telemetry ?? {
          'heartRate': 78,
          'bloodPressure': '124/82',
          'spo2': 98,
          'device': 'boAt Wave Pro BLE Stream',
        },
        medications: ['Telmisartan 40mg OD', 'Atorvastatin 10mg'],
        recentObservations: 'Daily ambulatory monitoring active. Resting pulse stable.',
      );

      if (mounted) {
        setState(() {
          _insight = res;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not retrieve Clinical Co-Pilot telemetry summary.';
          _isLoading = false;
        });
      }
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'CRITICAL':
        return ClinicalColors.crimsonRose;
      case 'OBSERVATION_REQUIRED':
        return ClinicalColors.warningAmber;
      case 'STABLE':
      default:
        return ClinicalColors.optimalEmerald;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: ClinicalRadii.roundedLg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ClinicalColors.optimalWash,
                    borderRadius: ClinicalRadii.roundedSm,
                  ),
                  child: const Icon(Icons.auto_awesome, color: ClinicalColors.primaryTeal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Physician Co-Pilot Telemetry Summary',
                        style: ClinicalTypography.headlineSm(color: ClinicalColors.deepSlateNavy)
                            .copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.patientName} (${widget.gender}, ${widget.age} yrs)',
                        style: ClinicalTypography.bodySm(color: ClinicalColors.textMuted).copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: ClinicalColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: ClinicalColors.hairlineBorder, height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: ClinicalColors.primaryTeal),
                          SizedBox(height: 14),
                          Text(
                            'Synthesizing clinical vitals & AI co-pilot telemetry...',
                            style: TextStyle(fontSize: 13, color: ClinicalColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: ClinicalColors.crimsonRose, size: 40),
                              const SizedBox(height: 10),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: ClinicalColors.textMuted),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadTelemetrySummary,
                                style: ElevatedButton.styleFrom(backgroundColor: ClinicalColors.primaryTeal),
                                child: const Text('Retry Analysis', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Risk Level Header Card
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _getRiskColor(_insight!.riskAssessment).withOpacity(0.08),
                                  borderRadius: ClinicalRadii.roundedMd,
                                  border: Border.all(
                                    color: _getRiskColor(_insight!.riskAssessment).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getRiskColor(_insight!.riskAssessment),
                                        borderRadius: ClinicalRadii.roundedFull,
                                      ),
                                      child: Text(
                                        _insight!.riskAssessment.replaceAll('_', ' '),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Provider: ${_insight!.provider.toUpperCase()}',
                                      style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                                          .copyWith(fontSize: 10.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Clinical Summary Card
                              Text(
                                'CLINICAL SYNTHESIS',
                                style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                                    .copyWith(fontSize: 11, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: ClinicalRadii.roundedMd,
                                  border: Border.all(color: ClinicalColors.hairlineBorder),
                                ),
                                child: Text(
                                  _insight!.clinicalSummary,
                                  style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                                      .copyWith(fontSize: 13, height: 1.45),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Vital Anomalies
                              Text(
                                'VITAL ANOMALIES & FLAGS',
                                style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                                    .copyWith(fontSize: 11, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 6),
                              if (_insight!.vitalAnomalies.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: ClinicalColors.optimalWash.withOpacity(0.5),
                                    borderRadius: ClinicalRadii.roundedSm,
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: ClinicalColors.optimalEmerald, size: 18),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'No vital anomalies detected. Resting metrics within target.',
                                          style: TextStyle(fontSize: 12, color: ClinicalColors.optimalEmerald, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ..._insight!.vitalAnomalies.map((anomaly) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: ClinicalRadii.roundedSm,
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_amber_rounded, color: ClinicalColors.crimsonRose, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            anomaly,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              const SizedBox(height: 16),

                              // Suggested Interventions
                              Text(
                                'SUGGESTED CLINICAL INTERVENTIONS',
                                style: ClinicalTypography.labelSm(color: ClinicalColors.textMuted)
                                    .copyWith(fontSize: 11, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 6),
                              ..._insight!.suggestedInterventions.map((intervention) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: ClinicalRadii.roundedSm,
                                    border: Border.all(color: ClinicalColors.hairlineBorder),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.arrow_right_alt_rounded, color: ClinicalColors.primaryTeal, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          intervention,
                                          style: ClinicalTypography.bodySm(color: ClinicalColors.deepSlateNavy)
                                              .copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
            ),

            const Divider(color: ClinicalColors.hairlineBorder, height: 20),

            // Close Action
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ClinicalColors.hairlineBorder),
                  shape: RoundedRectangleBorder(borderRadius: ClinicalRadii.roundedMd),
                ),
                child: const Text('Close Telemetry Co-Pilot', style: TextStyle(color: ClinicalColors.deepSlateNavy)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
