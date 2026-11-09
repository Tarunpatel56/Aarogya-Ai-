import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { Role, VerificationStatus, BedType, BedStatus, EmergencyStatus } from '@prisma/client';
import { tokenService } from '../src/services/token.service';
import { socketService } from '../src/services/socket.service';

describe('Phase 2 Ecosystem Backend Tests (Socket.IO, Prescriptions, Wards & Real Dispatches)', () => {
  let patientToken: string;
  let doctorToken: string;
  let hospitalAdminToken: string;
  let driverToken: string;

  let patientUserId: string;
  let patientProfileId: string;
  let doctorUserId: string;
  let doctorProfileId: string;
  let hospitalAdminUserId: string;
  let driverUserId: string;

  let testHospitalId: string;
  let testBedId: string;
  let testEmergencyId: string;
  let testPrescriptionId: string;

  beforeAll(async () => {
    // 1. Seed Patient User & Profile
    const patientUser = await prisma.user.create({
      data: {
        email: `phase2_patient_${Date.now()}@aarogya.ai`,
        passwordHash: 'argon2_dummy_hash_for_testing',
        role: Role.PATIENT,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    patientUserId = patientUser.id;
    const patientProfile = await prisma.patientProfile.create({
      data: {
        userId: patientUserId,
        fullName: 'Test Ecosystem Patient',
        dateOfBirth: new Date('1990-05-15'),
        gender: 'Male',
        bloodGroup: 'B+',
      },
    });
    patientProfileId = patientProfile.id;
    patientToken = tokenService.signAccessToken({
      id: patientUserId,
      email: patientUser.email,
      role: Role.PATIENT,
      verificationStatus: VerificationStatus.VERIFIED,
    });

    // 2. Seed Doctor User & Profile
    const doctorUser = await prisma.user.create({
      data: {
        email: `phase2_doctor_${Date.now()}@aarogya.ai`,
        passwordHash: 'argon2_dummy_hash_for_testing',
        role: Role.DOCTOR,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    doctorUserId = doctorUser.id;
    const doctorProfile = await prisma.doctorProfile.create({
      data: {
        userId: doctorUserId,
        fullName: 'Dr. Phase Two Specialist',
        specialization: 'Emergency Medicine',
        qualifications: 'MBBS, MD',
        nmcRegistrationNumber: `NMC-PHASE2-${Date.now()}`,
        hospitalAffiliation: 'AIIMS New Delhi',
        consultationFee: 750,
      },
    });
    doctorProfileId = doctorProfile.id;
    doctorToken = tokenService.signAccessToken({
      id: doctorUserId,
      email: doctorUser.email,
      role: Role.DOCTOR,
      verificationStatus: VerificationStatus.VERIFIED,
    });

    // 3. Seed Hospital Admin User & Hospital
    const adminUser = await prisma.user.create({
      data: {
        email: `phase2_admin_${Date.now()}@aarogya.ai`,
        passwordHash: 'argon2_dummy_hash_for_testing',
        role: Role.HOSPITAL_ADMIN,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    hospitalAdminUserId = adminUser.id;
    await prisma.hospitalAdminProfile.create({
      data: {
        userId: hospitalAdminUserId,
        fullName: 'Hospital Admin User',
        hospitalName: 'AIIMS Main Trauma',
        hospitalLicenseNumber: `HOSP-LIC-${Date.now()}`,
        designation: 'Operations Chief',
      },
    });
    hospitalAdminToken = tokenService.signAccessToken({
      id: hospitalAdminUserId,
      email: adminUser.email,
      role: Role.HOSPITAL_ADMIN,
      verificationStatus: VerificationStatus.VERIFIED,
    });

    const hospital = await prisma.hospital.create({
      data: {
        name: 'AIIMS Main Trauma Centre',
        licenseNumber: `AIIMS-LIC-${Date.now()}`,
        address: 'Ring Road, Ansari Nagar East',
        city: 'New Delhi',
        state: 'Delhi',
        latitude: 28.5672,
        longitude: 77.2100,
        contactPhone: '+91 11 2658 8500',
        emergencyPhone: '102',
        availableIcuBeds: 5,
        totalIcuBeds: 20,
        availableNormalBeds: 30,
        totalNormalBeds: 100,
        hasEmergencyBay: true,
        hasTraumaCenter: true,
      },
    });
    testHospitalId = hospital.id;

    // 4. Seed Ambulance Driver
    const driverUser = await prisma.user.create({
      data: {
        email: `phase2_driver_${Date.now()}@aarogya.ai`,
        passwordHash: 'argon2_dummy_hash_for_testing',
        role: Role.AMBULANCE_DRIVER,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    driverUserId = driverUser.id;
    await prisma.ambulanceStaffProfile.create({
      data: {
        userId: driverUserId,
        fullName: 'Ecosystem Paramedic Lead',
        staffRole: Role.AMBULANCE_DRIVER,
        licenseNumber: `DL-DRV-${Date.now()}`,
        assignedVehicleNumber: 'DL-01-AMB-9988',
      },
    });
    driverToken = tokenService.signAccessToken({
      id: driverUserId,
      email: driverUser.email,
      role: Role.AMBULANCE_DRIVER,
      verificationStatus: VerificationStatus.VERIFIED,
    });
  });

  afterAll(async () => {
    // Cleanup created test records
    await prisma.prescriptionItem.deleteMany({
      where: { prescription: { doctorProfileId } },
    });
    await prisma.prescription.deleteMany({
      where: { doctorProfileId },
    });
    await prisma.emergencyRequest.deleteMany({
      where: { patientProfileId },
    });
    await prisma.hospitalBed.deleteMany({
      where: { hospitalId: testHospitalId },
    });
    await prisma.hospitalDepartment.deleteMany({
      where: { hospitalId: testHospitalId },
    });
    await prisma.hospital.deleteMany({
      where: { id: testHospitalId },
    });
    await prisma.doctorProfile.deleteMany({ where: { id: doctorProfileId } });
    await prisma.patientProfile.deleteMany({ where: { id: patientProfileId } });
    await prisma.ambulanceStaffProfile.deleteMany({ where: { userId: driverUserId } });
    await prisma.hospitalAdminProfile.deleteMany({ where: { userId: hospitalAdminUserId } });
    const userIdsToCleanup = [patientUserId, doctorUserId, hospitalAdminUserId, driverUserId].filter(Boolean);
    if (userIdsToCleanup.length > 0) {
      await prisma.user.deleteMany({
        where: { id: { in: userIdsToCleanup } },
      });
    }
  });

  describe('1. Digital Prescriptions Lifecycle', () => {
    it('creates a digital prescription authored by a verified doctor', async () => {
      const payload = {
        patientProfileId,
        diagnosis: 'Acute Bronchitis & Seasonal Dyspnea',
        doctorNotes: 'Maintain hydration and monitor peak expiratory flow.',
        generalAdvice: 'Steam inhalation twice daily; avoid cold exposures.',
        followUpDate: new Date(Date.now() + 7 * 86400000).toISOString(),
        items: [
          {
            medicineName: 'Azithromycin',
            dosage: '500mg',
            frequency: '1-0-0',
            durationDays: 3,
            timing: 'After breakfast',
            instructions: 'Complete full 3-day course',
          },
          {
            medicineName: 'Levocetirizine',
            dosage: '5mg',
            frequency: '0-0-1',
            durationDays: 5,
            timing: 'At bedtime',
          },
        ],
      };

      const res = await request(app)
        .post('/api/v1/prescriptions')
        .set('Authorization', `Bearer ${doctorToken}`)
        .send(payload);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.prescription.diagnosis).toBe('Acute Bronchitis & Seasonal Dyspnea');
      expect(res.body.data.prescription.items).toHaveLength(2);
      expect(res.body.data.prescription.doctorProfile.fullName).toBe('Dr. Phase Two Specialist');

      testPrescriptionId = res.body.data.prescription.id;
    });

    it('allows patient to fetch their authored digital prescriptions', async () => {
      const res = await request(app)
        .get(`/api/v1/prescriptions/patient/${patientProfileId}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.prescriptions).toBeInstanceOf(Array);
      expect(res.body.data.prescriptions.length).toBeGreaterThanOrEqual(1);

      const found = res.body.data.prescriptions.find((p: any) => p.id === testPrescriptionId);
      expect(found).toBeDefined();
      expect(found.items[0].medicineName).toBe('Azithromycin');
    });

    it('rejects patient trying to view another patient prescriptions', async () => {
      const otherPatientUser = await prisma.user.create({
        data: {
          email: `other_patient_${Date.now()}@aarogya.ai`,
          passwordHash: 'dummy',
          role: Role.PATIENT,
        },
      });
      const otherProfile = await prisma.patientProfile.create({
        data: {
          userId: otherPatientUser.id,
          fullName: 'Other Patient',
        },
      });

      const res = await request(app)
        .get(`/api/v1/prescriptions/patient/${otherProfile.id}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(res.status).toBe(403);

      await prisma.patientProfile.delete({ where: { id: otherProfile.id } });
      await prisma.user.delete({ where: { id: otherPatientUser.id } });
    });
  });

  describe('2. Hospital Wards & Bed Inventory Management', () => {
    it('retrieves granular bed inventory and auto-initializes defaults if empty', async () => {
      const res = await request(app)
        .get(`/api/v1/hospitals/${testHospitalId}/beds`)
        .set('Authorization', `Bearer ${hospitalAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.beds.length).toBeGreaterThanOrEqual(5);

      const icuBed = res.body.data.beds.find((b: any) => b.bedType === 'ICU');
      expect(icuBed).toBeDefined();
      testBedId = icuBed.id;
    });

    it('updates bed status from AVAILABLE to OCCUPIED and syncs summary', async () => {
      const res = await request(app)
        .patch(`/api/v1/hospitals/${testHospitalId}/beds/${testBedId}`)
        .set('Authorization', `Bearer ${hospitalAdminToken}`)
        .send({
          status: 'OCCUPIED',
          occupiedByPatient: 'Ramesh Sharma (Admitted via EMS)',
          notes: 'Post-op cardiac monitoring',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.bed.status).toBe('OCCUPIED');
      expect(res.body.data.bed.occupiedByPatient).toBe('Ramesh Sharma (Admitted via EMS)');
    });
  });

  describe('3. Real Driver Dispatches & PostgreSQL Trip Assignment', () => {
    it('creates an emergency request and driver accepts it from PostgreSQL', async () => {
      // 1. Patient triggers SOS
      const sosRes = await request(app)
        .post('/api/v1/emergency/sos')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          latitude: 28.5672,
          longitude: 77.2100,
          pickupAddress: 'Block C, Ansari Nagar East',
        });

      expect(sosRes.status).toBe(201);
      testEmergencyId = sosRes.body.data.emergency.id;

      // 2. Driver fetches available dispatches
      const dispatchesRes = await request(app)
        .get('/api/v1/drivers/dispatches')
        .set('Authorization', `Bearer ${driverToken}`);

      expect(dispatchesRes.status).toBe(200);
      expect(dispatchesRes.body.data.dispatches).toBeInstanceOf(Array);

      // 3. Driver accepts dispatch
      const acceptRes = await request(app)
        .post(`/api/v1/drivers/trips/${testEmergencyId}/accept`)
        .set('Authorization', `Bearer ${driverToken}`);

      expect(acceptRes.status).toBe(200);
      expect(acceptRes.body.success).toBe(true);
      expect(acceptRes.body.data.emergency.assignedDriverId).toBe(driverUserId);
      expect(acceptRes.body.data.emergency.status).toBe('ASSIGNED');

      // 4. Driver reports milestone: EN_ROUTE
      const statusRes = await request(app)
        .patch(`/api/v1/drivers/me/trips/${testEmergencyId}/status`)
        .set('Authorization', `Bearer ${driverToken}`)
        .send({
          status: 'EN_ROUTE',
          latitude: 28.5690,
          longitude: 77.2115,
        });

      expect(statusRes.status).toBe(200);
      expect(statusRes.body.data.trip.status).toBe('EN_ROUTE');
    });
  });

  describe('4. Socket.IO Service Emission Helpers', () => {
    it('verifies socket broadcast helpers execute safely', () => {
      expect(() => {
        socketService.emitEmergencyBroadcast({ id: 'test-sos-broadcast' });
        socketService.emitEmergencyAccepted('test-sos-broadcast', { driverName: 'Paramedic Lead' });
        socketService.emitEmergencyStatusUpdate('test-sos-broadcast', 'EN_ROUTE');
        socketService.emitAmbulanceLocation('test-sos-broadcast', { latitude: 28.5, longitude: 77.2 });
        socketService.emitHospitalTraumaAlert(testHospitalId, { emergencyId: 'test-sos-broadcast' });
        socketService.emitPrescriptionCreated(patientUserId, { id: 'test-rx-broadcast' });
      }).not.toThrow();
    });
  });
});
