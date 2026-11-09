import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aarogya/models/hospital_model.dart';
import 'package:aarogya/models/emergency_model.dart';
import 'package:aarogya/models/appointment_model.dart';
import 'package:aarogya/screens/hospitals/nearby_hospitals_screen.dart';
import 'package:aarogya/screens/emergency/live_ambulance_tracking_screen.dart';
import 'package:aarogya/screens/appointments/consultation_room_screen.dart';
import 'package:aarogya/services/hospital_service.dart';
import 'package:aarogya/services/emergency_service.dart';

class MockHospitalService extends HospitalService {
  @override
  Future<List<HospitalModel>> getNearbyHospitals({
    double? latitude,
    double? longitude,
    double? radiusKm,
    bool? emergencyBay,
  }) async {
    return [
      const HospitalModel(
        id: 'hosp-1',
        name: 'AIIMS New Delhi',
        licenseNumber: 'DL-001',
        address: 'Ansari Nagar, New Delhi',
        city: 'New Delhi',
        state: 'Delhi',
        latitude: 28.5672,
        longitude: 77.2100,
        contactPhone: '+91-11-26588500',
        emergencyPhone: '102',
        availableIcuBeds: 24,
        totalIcuBeds: 120,
        availableNormalBeds: 145,
        totalNormalBeds: 850,
        hasEmergencyBay: true,
        hasTraumaCenter: true,
        distanceKm: 2.4,
      ),
      const HospitalModel(
        id: 'hosp-2',
        name: 'Max Super Speciality',
        licenseNumber: 'DL-002',
        address: 'Saket, New Delhi',
        city: 'New Delhi',
        state: 'Delhi',
        latitude: 28.5284,
        longitude: 77.2120,
        contactPhone: '+91-11-26515050',
        emergencyPhone: '+91-11-40554055',
        availableIcuBeds: 14,
        totalIcuBeds: 65,
        availableNormalBeds: 76,
        totalNormalBeds: 320,
        hasEmergencyBay: true,
        hasTraumaCenter: true,
        distanceKm: 4.8,
      ),
    ];
  }
}

class MockEmergencyService extends EmergencyService {
  @override
  Future<EmergencyModel> simulateStep(String id) async {
    return EmergencyModel(
      id: id,
      patientProfileId: 'patient-1',
      latitude: 28.5672,
      longitude: 77.2100,
      assignedVehicleNo: 'DL-01-AMB-4402',
      hospitalName: 'AIIMS Emergency Bay',
      status: 'EN_ROUTE',
      estimatedMinutes: 5,
      driverName: 'Vikram Singh',
      driverPhone: '+91-9876543210',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<EmergencyModel> cancelEmergency(String id) async {
    return EmergencyModel(
      id: id,
      patientProfileId: 'patient-1',
      latitude: 28.5672,
      longitude: 77.2100,
      assignedVehicleNo: 'DL-01-AMB-4402',
      hospitalName: 'AIIMS Emergency Bay',
      status: 'CANCELLED',
      estimatedMinutes: 0,
      driverName: 'Vikram Singh',
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  group('Phase 4 & 5 Integration Widget Tests', () {
    testWidgets('NearbyHospitalsScreen renders verified hospitals and live bed counts', (tester) async {
      final mockService = MockHospitalService();

      await tester.pumpWidget(
        MaterialApp(
          home: NearbyHospitalsScreen(hospitalService: mockService),
        ),
      );

      // Verify loading state finishes
      await tester.pumpAndSettle();

      expect(find.text('Nearby Hospitals & Verified Beds'), findsOneWidget);
      expect(find.text('AIIMS New Delhi'), findsOneWidget);
      expect(find.text('Max Super Speciality'), findsOneWidget);
      expect(find.text('24 Available / 120'), findsOneWidget);
      expect(find.text('24/7 Emergency Bay'), findsNWidgets(2));
      expect(find.text('2.4 km'), findsOneWidget);
    });

    testWidgets('LiveAmbulanceTrackingScreen renders radar, ETA and paramedic details', (tester) async {
      final mockEmergency = EmergencyModel(
        id: 'emg-123',
        patientProfileId: 'patient-1',
        latitude: 28.5672,
        longitude: 77.2100,
        assignedVehicleNo: 'DL-01-AMB-9988',
        hospitalName: 'AIIMS Trauma Bay',
        status: 'ASSIGNED',
        estimatedMinutes: 8,
        driverName: 'Vikram Singh (Paramedic Lead)',
        driverPhone: '+91-9876543210',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LiveAmbulanceTrackingScreen(
            emergencyService: MockEmergencyService(),
            initialEmergency: mockEmergency,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Live Ambulance Tracking'), findsOneWidget);
      expect(find.text('DL-01-AMB-9988'), findsWidgets);
      expect(find.text('Estimated Arrival in ~8 minutes'), findsOneWidget);
      expect(find.text('Vikram Singh (Paramedic Lead)'), findsOneWidget);
      expect(find.text('AIIMS Trauma Bay'), findsOneWidget);
      expect(find.text('Cancel Emergency Request'), findsOneWidget);
    });

    testWidgets('ConsultationRoomScreen renders live video controls and doctor profile', (tester) async {
      final mockAppointment = AppointmentModel(
        id: 'appt-1',
        patientProfileId: 'p1',
        doctorProfileId: 'd1',
        doctorName: 'Dr. Ananya Sharma',
        doctorSpecialization: 'Cardiologist',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(minutes: 30)),
        status: 'CONFIRMED',
        mode: 'ONLINE',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConsultationRoomScreen(appointment: mockAppointment),
        ),
      );

      await tester.pump();

      expect(find.text('Dr. Ananya Sharma'), findsOneWidget);
      expect(find.text('Cardiologist'), findsOneWidget);
      expect(find.text('Prescription'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.call_end), findsOneWidget);
    });
  });
}
