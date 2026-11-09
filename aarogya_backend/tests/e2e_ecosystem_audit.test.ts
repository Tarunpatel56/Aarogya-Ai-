import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '../src/app';
import { prisma } from '../src/config/prisma';
import { Role, VerificationStatus, BedStatus, AppointmentStatus, RecordType } from '@prisma/client';
import { tokenService } from '../src/services/token.service';
import { passwordService } from '../src/services/password.service';
import { socketService } from '../src/services/socket.service';

describe('Comprehensive End-to-End API Audit & Cross-App Ecosystem Verification', () => {
  const runId = Date.now().toString().slice(-6);

  // User Identifiers & Tokens
  let patientUser: any;
  let patientProfile: any;
  let patientToken: string;

  let doctorUser: any;
  let doctorProfile: any;
  let doctorToken: string;

  let hospitalAdminUser: any;
  let hospitalAdminProfile: any;
  let hospitalAdminToken: string;
  let testHospital: any;

  let driverUser: any;
  let driverProfile: any;
  let driverToken: string;

  // Shared Workflow Entities
  let createdAppointmentId: string;
  let createdPrescriptionId: string;
  let createdEmergencyId: string;
  let createdFamilyMemberId: string;
  let createdMedicineReminderId: string;
  let createdMedicalRecordId: string;
  let testBedId: string;

  beforeAll(async () => {
    const passwordHash = await passwordService.hash('Password123!');

    // 1. Seed Isolated Verified Patient
    patientUser = await prisma.user.create({
      data: {
        email: `audit_patient_${runId}@aarogya.test`,
        phone: `9100${runId}1`,
        passwordHash,
        role: Role.PATIENT,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    patientProfile = await prisma.patientProfile.create({
      data: {
        userId: patientUser.id,
        fullName: 'Audit Patient Ananya',
        dateOfBirth: new Date('1995-04-12'),
        gender: 'Female',
        bloodGroup: 'O+',
        allergies: 'Penicillin, NSAIDs',
        address: 'B-402 Green Park, New Delhi',
      },
    });
    patientToken = tokenService.signAccessToken({
      id: patientUser.id,
      email: patientUser.email,
      role: Role.PATIENT,
      verificationStatus: VerificationStatus.VERIFIED,
    });

    // 2. Seed Isolated Verified Doctor with Active Availability
    doctorUser = await prisma.user.create({
      data: {
        email: `audit_doctor_${runId}@aarogya.test`,
        phone: `9100${runId}2`,
        passwordHash,
        role: Role.DOCTOR,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    doctorProfile = await prisma.doctorProfile.create({
      data: {
        userId: doctorUser.id,
        fullName: 'Dr. Siddharth Rao',
        nmcRegistrationNumber: `NMC-AUDIT-${runId}`,
        specialization: 'Pulmonology & Critical Care',
        qualifications: 'MBBS, MD, FCCP',
        experienceYears: 12,
        hospitalAffiliation: 'Apollo Multispeciality',
        consultationFee: 800,
        languages: ['English', 'Hindi'],
      },
    });
    doctorToken = tokenService.signAccessToken({
      id: doctorUser.id,
      email: doctorUser.email,
      role: Role.DOCTOR,
      verificationStatus: VerificationStatus.VERIFIED,
    });

    // Create doctor availability covering current and future dates
    const startWindow = new Date();
    startWindow.setHours(0, 0, 0, 0);
    const endWindow = new Date();
    endWindow.setDate(endWindow.getDate() + 30);
    endWindow.setHours(23, 59, 59, 999);

    await prisma.doctorAvailability.create({
      data: {
        doctorProfileId: doctorProfile.id,
        startTime: startWindow,
        endTime: endWindow,
        status: 'AVAILABLE',
      },
    });

    // 3. Seed Hospital Admin & Hospital
    hospitalAdminUser = await prisma.user.create({
      data: {
        email: `audit_hosp_admin_${runId}@aarogya.test`,
        phone: `9100${runId}3`,
        passwordHash,
        role: Role.HOSPITAL_ADMIN,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    hospitalAdminProfile = await prisma.hospitalAdminProfile.create({
      data: {
        userId: hospitalAdminUser.id,
        fullName: 'Dr. V. K. Paul (Medical Superintendent)',
        hospitalName: `Apollo Multispeciality ${runId}`,
        hospitalLicenseNumber: `HOSP-REG-${runId}`,
        designation: 'Director of Clinical Services',
      },
    });
    hospitalAdminToken = tokenService.signAccessToken({
      id: hospitalAdminUser.id,
      email: hospitalAdminUser.email,
      role: Role.HOSPITAL_ADMIN,
      verificationStatus: VerificationStatus.VERIFIED,
    });

    testHospital = await prisma.hospital.create({
      data: {
        name: `Apollo Multispeciality ${runId}`,
        licenseNumber: `HOSP-LIC-${runId}`,
        address: 'Sarita Vihar, Delhi Mathura Road',
        city: 'New Delhi',
        state: 'Delhi',
        latitude: 28.5355,
        longitude: 77.2882,
        contactPhone: '+91 11 2692 5858',
        emergencyPhone: '102',
        availableIcuBeds: 10,
        totalIcuBeds: 30,
        availableNormalBeds: 50,
        totalNormalBeds: 150,
        hasEmergencyBay: true,
        hasTraumaCenter: true,
      },
    });

    // 4. Seed Ambulance Driver
    driverUser = await prisma.user.create({
      data: {
        email: `audit_driver_${runId}@aarogya.test`,
        phone: `9100${runId}4`,
        passwordHash,
        role: Role.AMBULANCE_DRIVER,
        verificationStatus: VerificationStatus.VERIFIED,
        isActive: true,
      },
    });
    driverProfile = await prisma.ambulanceStaffProfile.create({
      data: {
        userId: driverUser.id,
        fullName: 'Ravi Kumar (ALS Paramedic)',
        staffRole: Role.AMBULANCE_DRIVER,
        licenseNumber: `DL-DRV-${runId}`,
        assignedVehicleNumber: 'DL-01-AMB-5544',
      },
    });
    expect(driverProfile.id).toBeDefined();
    driverToken = tokenService.signAccessToken({
      id: driverUser.id,
      email: driverUser.email,
      role: Role.AMBULANCE_DRIVER,
      verificationStatus: VerificationStatus.VERIFIED,
    });
  });

  afterAll(async () => {
    // Isolated Cleanup
    const userIds = [patientUser?.id, doctorUser?.id, hospitalAdminUser?.id, driverUser?.id].filter(Boolean);
    if (userIds.length > 0) {
      await prisma.prescriptionItem.deleteMany({
        where: { prescription: { doctorProfileId: doctorProfile?.id } },
      });
      await prisma.prescription.deleteMany({
        where: { doctorProfileId: doctorProfile?.id },
      });
      await prisma.emergencyRequest.deleteMany({
        where: { patientProfileId: patientProfile?.id },
      });
      await prisma.hospitalBed.deleteMany({
        where: { hospitalId: testHospital?.id },
      });
      await prisma.hospitalDepartment.deleteMany({
        where: { hospitalId: testHospital?.id },
      });
      await prisma.hospital.deleteMany({
        where: { id: testHospital?.id },
      });
      await prisma.doctorAvailability.deleteMany({
        where: { doctorProfileId: doctorProfile?.id },
      });
      await prisma.appointment.deleteMany({
        where: { patientProfileId: patientProfile?.id },
      });
      await prisma.patientProfile.deleteMany({
        where: { userId: { in: userIds } },
      });
      await prisma.doctorProfile.deleteMany({
        where: { userId: { in: userIds } },
      });
      await prisma.hospitalAdminProfile.deleteMany({
        where: { userId: { in: userIds } },
      });
      await prisma.ambulanceStaffProfile.deleteMany({
        where: { userId: { in: userIds } },
      });
      await prisma.user.deleteMany({
        where: { id: { in: userIds } },
      });
    }
  });

  // ============================================================================
  // PHASE 2: PATIENT APP API AUDIT
  // ============================================================================
  describe('Phase 2 — Patient App API Verification', () => {
    it('1. POST /auth/register/patient - Registers a new patient with valid validation', async () => {
      const email = `new_pat_${Date.now()}@aarogya.test`;
      const res = await request(app)
        .post('/api/v1/auth/register/patient')
        .send({
          email,
          password: 'Password123!',
          fullName: 'Test Patient Registration',
          bloodGroup: 'A+',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.role).toBe(Role.PATIENT);
      expect(res.body.data.tokens).toHaveProperty('accessToken');
      expect(res.body.data.tokens).toHaveProperty('refreshToken');

      // Cleanup registration test user
      await prisma.patientProfile.deleteMany({ where: { userId: res.body.data.user.id } });
      await prisma.user.delete({ where: { id: res.body.data.user.id } });
    });

    it('2. POST /auth/login - Authenticates patient credentials and returns JWT token pair', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          email: patientUser.email,
          password: 'Password123!',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.id).toBe(patientUser.id);
      expect(res.body.data.tokens).toHaveProperty('accessToken');
    });

    it('3. POST /auth/send-otp & /auth/verify-otp - Generates and verifies OTP challenge', async () => {
      const sendRes = await request(app)
        .post('/api/v1/auth/send-otp')
        .send({ phone: patientUser.phone });

      expect(sendRes.status).toBe(200);
      expect(sendRes.body.success).toBe(true);

      const verifyRes = await request(app)
        .post('/api/v1/auth/verify-otp')
        .send({ phone: patientUser.phone, otp: '123456' });

      expect(verifyRes.status).toBe(200);
      expect(verifyRes.body.success).toBe(true);
      expect(verifyRes.body.data).toHaveProperty('tokens');
    });

    it('4. POST /auth/forgot-password & /auth/reset-password - Dispatches reset and updates credential', async () => {
      const forgotRes = await request(app)
        .post('/api/v1/auth/forgot-password')
        .send({ email: patientUser.email });

      expect(forgotRes.status).toBe(200);
      expect(forgotRes.body.success).toBe(true);

      const resetRes = await request(app)
        .post('/api/v1/auth/reset-password')
        .send({ email: patientUser.email, newPassword: 'NewPassword123!' });

      expect(resetRes.status).toBe(200);
      expect(resetRes.body.success).toBe(true);

      // Verify can login with new password
      const reLogin = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: patientUser.email, password: 'NewPassword123!' });

      expect(reLogin.status).toBe(200);
    });

    it('5. GET & PATCH /patients/me - Retrieves and updates patient profile fields', async () => {
      const getRes = await request(app)
        .get('/api/v1/patients/me')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(getRes.status).toBe(200);
      expect(getRes.body.data.profile.fullName).toBe('Audit Patient Ananya');
      expect(getRes.body.data.profile.bloodGroup).toBe('O+');

      const patchRes = await request(app)
        .patch('/api/v1/patients/me')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          allergies: 'Penicillin, Dust, Sulfa',
          emergencyContactName: 'Dr. Ramesh Sharma',
          emergencyContactPhone: '9876543210',
        });

      expect(patchRes.status).toBe(200);
      expect(patchRes.body.data.profile.allergies).toBe('Penicillin, Dust, Sulfa');
      expect(patchRes.body.data.profile.emergencyContactName).toBe('Dr. Ramesh Sharma');
    });

    it('6. Family Members CRUD (/patients/me/family-members)', async () => {
      // Create family member
      const addRes = await request(app)
        .post('/api/v1/patients/me/family-members')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          fullName: 'Suresh Sharma',
          relationship: 'Father',
          dateOfBirth: '1962-08-20',
          bloodGroup: 'B+',
          medicalHistory: 'Hypertension, Diabetes Type-2',
        });

      expect(addRes.status).toBe(201);
      expect(addRes.body.data.familyMember.fullName).toBe('Suresh Sharma');
      createdFamilyMemberId = addRes.body.data.familyMember.id;

      // Update family member
      const updateRes = await request(app)
        .patch(`/api/v1/patients/me/family-members/${createdFamilyMemberId}`)
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          bloodGroup: 'O+',
          medicalHistory: 'Hypertension (Controlled via Amlodipine)',
        });

      expect(updateRes.status).toBe(200);
      expect(updateRes.body.data.familyMember.bloodGroup).toBe('O+');

      // List family members
      const listRes = await request(app)
        .get('/api/v1/patients/me/family-members')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(listRes.status).toBe(200);
      expect(listRes.body.data.familyMembers.length).toBeGreaterThanOrEqual(1);

      // Delete family member
      const delRes = await request(app)
        .delete(`/api/v1/patients/me/family-members/${createdFamilyMemberId}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(delRes.status).toBe(200);
    });

    it('7. Medical Records CRUD (/patients/me/medical-records)', async () => {
      const createRes = await request(app)
        .post('/api/v1/patients/me/medical-records')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          recordType: RecordType.LAB_REPORT,
          title: 'Lipid Profile & HbA1c Panel',
          description: 'Fasting blood glucose 98 mg/dL, HbA1c 5.4%',
          issuingDoctor: 'Dr. Diagnostic Pathologist',
          facilityName: 'National Diagnostics Centre',
          documentMetadata: {
            fileRef: 'records/2026/lipid_panel.pdf',
            mimeType: 'application/pdf',
            fileSizeBytes: 182400,
          },
        });

      expect(createRes.status).toBe(201);
      expect(createRes.body.data.record.title).toBe('Lipid Profile & HbA1c Panel');
      createdMedicalRecordId = createRes.body.data.record.id;

      const getRes = await request(app)
        .get(`/api/v1/patients/me/medical-records/${createdMedicalRecordId}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(getRes.status).toBe(200);
      expect(getRes.body.data.record.issuingDoctor).toBe('Dr. Diagnostic Pathologist');
    });

    it('8. Medicine Reminders & Dose Adherence (/patients/me/medicine-reminders)', async () => {
      const addRes = await request(app)
        .post('/api/v1/patients/me/medicine-reminders')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          medicineName: 'Rosuvastatin 10mg',
          dosage: '1 Tablet',
          dosageForm: 'Tablet',
          frequency: 'Once Daily',
          reminderTimes: ['09:00 PM'],
          instructions: 'Take after dinner',
        });

      expect(addRes.status).toBe(201);
      createdMedicineReminderId = addRes.body.data.reminder.id;

      const doseRes = await request(app)
        .patch(`/api/v1/patients/me/medicine-reminders/${createdMedicineReminderId}/dose`)
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          status: 'TAKEN',
          scheduledTime: new Date().toISOString(),
        });

      expect(doseRes.status).toBe(201);
      expect(doseRes.body.data.doseLog.status).toBe('TAKEN');
    });

    it('9. Emergency SOS Creation & Tracking (/emergency/sos)', async () => {
      const sosRes = await request(app)
        .post('/api/v1/emergency/sos')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          latitude: 28.5355,
          longitude: 77.2882,
          pickupAddress: 'Sarita Vihar Pocket C, New Delhi',
          vitalsSnapshot: { heartRate: 118, spo2: 92 },
        });

      expect(sosRes.status).toBe(201);
      expect(sosRes.body.data.emergency).toHaveProperty('id');
      createdEmergencyId = sosRes.body.data.emergency.id;

      const trackRes = await request(app)
        .get(`/api/v1/emergency/sos/${createdEmergencyId}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(trackRes.status).toBe(200);
      expect(trackRes.body.data.emergency.id).toBe(createdEmergencyId);
    });

    it('10. AI Chat, Symptom Triage & Medicine OCR Endpoints', async () => {
      // Symptom Triage
      const triageRes = await request(app)
        .post('/api/v1/ai/triage')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          symptoms: 'Persistent dry cough, mild fever, sore throat for 3 days',
          severity: 'MODERATE',
        });

      expect(triageRes.status).toBe(200);
      expect(triageRes.body.success).toBe(true);
      expect(triageRes.body.data).toHaveProperty('urgencyLevel');
      expect(triageRes.body.data).toHaveProperty('summary');

      // Medicine OCR Parsing
      const ocrRes = await request(app)
        .post('/api/v1/ai/analyze-medicine')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          ocrText: 'PARACETAMOL TABLETS IP 650 MG DOLO-650 Batch No: DL2415 Mfd: 01/2026',
        });

      expect(ocrRes.status).toBe(200);
      expect(ocrRes.body.data).toHaveProperty('medicineName');
    }, 35000);
  });

  // ============================================================================
  // PHASE 3: DOCTOR & HOSPITAL APP API AUDIT
  // ============================================================================
  describe('Phase 3 — Doctor & Hospital App API Verification', () => {
    it('1. GET & PATCH /doctors/me - Retrieves and updates verified doctor profile', async () => {
      const getRes = await request(app)
        .get('/api/v1/doctors/me')
        .set('Authorization', `Bearer ${doctorToken}`);

      expect(getRes.status).toBe(200);
      expect(getRes.body.data.profile.fullName).toBe('Dr. Siddharth Rao');
      expect(getRes.body.data.profile.specialization).toBe('Pulmonology & Critical Care');

      const patchRes = await request(app)
        .patch('/api/v1/doctors/me')
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({
          bio: 'Senior Pulmonologist with expertise in interstitial lung disease and sleep medicine.',
          consultationFee: 850,
        });

      expect(patchRes.status).toBe(200);
      expect(patchRes.body.data.profile.consultationFee).toBe(850);
    });

    it('2. Doctor Availability Schedule Management (/doctors/me/availability)', async () => {
      const futureDate = new Date(Date.now() + 45 * 86400000);
      futureDate.setHours(10, 0, 0, 0);
      const futureDateEnd = new Date(futureDate.getTime() + 4 * 3600000);

      const addRes = await request(app)
        .post('/api/v1/doctors/me/availability')
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({
          startTime: futureDate.toISOString(),
          endTime: futureDateEnd.toISOString(),
          status: 'AVAILABLE',
        });

      expect(addRes.status).toBe(201);
      const availId = addRes.body.data.availability.id;

      const getRes = await request(app)
        .get('/api/v1/doctors/me/availability')
        .set('Authorization', `Bearer ${doctorToken}`);

      expect(getRes.status).toBe(200);
      expect(getRes.body.data.availabilities.length).toBeGreaterThanOrEqual(1);

      // Delete extra availability
      await request(app)
        .delete(`/api/v1/doctors/me/availability/${availId}`)
        .set('Authorization', `Bearer ${doctorToken}`);
    });

    it('3. Doctor OPD Appointments Queue & Status Operations', async () => {
      // 1. Patient requests appointment with doctor
      const slotTime = new Date(Date.now() + 2 * 86400000);
      slotTime.setHours(11, 0, 0, 0);

      const bookRes = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          doctorProfileId: doctorProfile.id,
          startTime: slotTime.toISOString(),
          durationMinutes: 30,
          reason: 'Persistent wheezing and nocturnal dyspnea',
          mode: 'IN_PERSON',
        });

      expect(bookRes.status).toBe(201);
      expect(bookRes.body.data.appointment.status).toBe(AppointmentStatus.REQUESTED);
      createdAppointmentId = bookRes.body.data.appointment.id;

      // 2. Doctor confirms appointment
      const confirmRes = await request(app)
        .patch(`/api/v1/appointments/${createdAppointmentId}/confirm`)
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({
          doctorNotes: 'Please bring recent spirometry and chest X-ray reports.',
        });

      expect(confirmRes.status).toBe(200);
      expect(confirmRes.body.data.appointment.status).toBe(AppointmentStatus.CONFIRMED);

      // 3. Reschedule Appointment API
      const newTime = new Date(slotTime.getTime() + 2 * 3600000); // 2 hours later
      const rescheduleRes = await request(app)
        .patch(`/api/v1/appointments/${createdAppointmentId}/reschedule`)
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({
          startTime: newTime.toISOString(),
          durationMinutes: 30,
          reason: 'Adjusted to fit afternoon pulmonary clinic',
        });

      expect(rescheduleRes.status).toBe(200);
      expect(rescheduleRes.body.data.appointment.startTime).toBeDefined();

      // 4. Complete consultation
      const completeRes = await request(app)
        .patch(`/api/v1/appointments/${createdAppointmentId}/complete`)
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({
          doctorNotes: 'Prescription written and post-consultation advice recorded.',
        });

      expect(completeRes.status).toBe(200);
      expect(completeRes.body.data.appointment.status).toBe(AppointmentStatus.COMPLETED);
    });

    it('4. Digital Prescription Authoring & Modification (/prescriptions)', async () => {
      // Doctor authors digital prescription
      const rxRes = await request(app)
        .post('/api/v1/prescriptions')
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({
          patientProfileId: patientProfile.id,
          appointmentId: createdAppointmentId,
          diagnosis: 'Bronchial Asthma with Allergic Rhinitis',
          doctorNotes: 'Review in 2 weeks or if symptoms worsen.',
          generalAdvice: 'Inhale through spacer; rinse mouth after budesonide.',
          items: [
            {
              medicineName: 'Formoterol + Budesonide Inhaler 200mcg',
              dosage: '2 Puffs',
              frequency: '1-0-1',
              durationDays: 14,
              instructions: 'Twice daily via spacer device',
            },
            {
              medicineName: 'Montelukast 10mg',
              dosage: '1 Tab',
              frequency: '0-0-1',
              durationDays: 14,
              timing: 'At bedtime',
            },
          ],
        });

      expect(rxRes.status).toBe(201);
      expect(rxRes.body.data.prescription.items).toHaveLength(2);
      createdPrescriptionId = rxRes.body.data.prescription.id;

      // Doctor updates prescription notes
      const updateRxRes = await request(app)
        .patch(`/api/v1/prescriptions/${createdPrescriptionId}`)
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({
          generalAdvice: 'Avoid cold beverages and aerosol sprays. Spacer technique verified.',
        });

      expect(updateRxRes.status).toBe(200);
      expect(updateRxRes.body.data.prescription.generalAdvice).toContain('Spacer technique verified');

      // Patient views prescription
      const patientRxRes = await request(app)
        .get(`/api/v1/prescriptions/patient/${patientProfile.id}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(patientRxRes.status).toBe(200);
      const foundRx = patientRxRes.body.data.prescriptions.find((p: any) => p.id === createdPrescriptionId);
      expect(foundRx).toBeDefined();
    });

    it('5. Hospital Wards, Beds & Staff Management (/hospitals)', async () => {
      // 1. Get hospital bed inventory
      const bedsRes = await request(app)
        .get(`/api/v1/hospitals/${testHospital.id}/beds`)
        .set('Authorization', `Bearer ${hospitalAdminToken}`);

      expect(bedsRes.status).toBe(200);
      expect(bedsRes.body.data.beds.length).toBeGreaterThanOrEqual(1);
      testBedId = bedsRes.body.data.beds[0].id;

      // 2. Admit patient to bed
      const admitRes = await request(app)
        .patch(`/api/v1/hospitals/${testHospital.id}/beds/${testBedId}`)
        .set('Authorization', `Bearer ${hospitalAdminToken}`)
        .send({
          status: BedStatus.OCCUPIED,
          occupiedByPatient: 'Audit Patient Ananya',
          notes: 'Admitted for observation under Dr. Rao',
        });

      expect(admitRes.status).toBe(200);
      expect(admitRes.body.data.bed.status).toBe(BedStatus.OCCUPIED);

      // 3. Discharge patient from bed
      const dischargeRes = await request(app)
        .patch(`/api/v1/hospitals/${testHospital.id}/beds/${testBedId}`)
        .set('Authorization', `Bearer ${hospitalAdminToken}`)
        .send({
          status: BedStatus.AVAILABLE,
          occupiedByPatient: null,
          notes: 'Discharged in stable condition. Ward sanitized.',
        });

      expect(dischargeRes.status).toBe(200);
      expect(dischargeRes.body.data.bed.status).toBe(BedStatus.AVAILABLE);

      // 4. Add doctor staff to hospital
      const addStaffRes = await request(app)
        .post('/api/v1/hospitals/me/staff')
        .set('Authorization', `Bearer ${hospitalAdminToken}`)
        .send({
          doctorId: doctorProfile.id,
        });

      expect(addStaffRes.status).toBe(200);
      expect(addStaffRes.body.data.doctor.hospitalAffiliation).toBe(hospitalAdminProfile.hospitalName);

      // 5. Query staff roster
      const staffRes = await request(app)
        .get('/api/v1/hospitals/me/staff')
        .set('Authorization', `Bearer ${hospitalAdminToken}`);

      expect(staffRes.status).toBe(200);
      expect(staffRes.body.data.staffCount).toBeGreaterThanOrEqual(1);
    });
  });

  // ============================================================================
  // PHASE 4: AMBULANCE APP API AUDIT
  // ============================================================================
  describe('Phase 4 — Ambulance App API Verification', () => {
    it('1. GET & PATCH /drivers/me - Retrieves and updates paramedic profile', async () => {
      const getRes = await request(app)
        .get('/api/v1/drivers/me')
        .set('Authorization', `Bearer ${driverToken}`);

      expect(getRes.status).toBe(200);
      expect(getRes.body.data.profile.fullName).toBe('Ravi Kumar (ALS Paramedic)');
      expect(getRes.body.data.profile.assignedVehicleNumber).toBe('DL-01-AMB-5544');

      const patchRes = await request(app)
        .patch('/api/v1/drivers/me')
        .set('Authorization', `Bearer ${driverToken}`)
        .send({
          certificationLevel: 'Advanced Cardiac Life Support (ACLS)',
        });

      expect(patchRes.status).toBe(200);
      expect(patchRes.body.data.profile.certificationLevel).toBe('Advanced Cardiac Life Support (ACLS)');
    });

    it('2. Driver Dispatches, Claiming & Milestone Progression', async () => {
      // 1. Driver queries available dispatches
      const dispatchesRes = await request(app)
        .get('/api/v1/drivers/dispatches')
        .set('Authorization', `Bearer ${driverToken}`);

      expect(dispatchesRes.status).toBe(200);
      expect(dispatchesRes.body.data.dispatches).toBeInstanceOf(Array);

      // 2. Driver accepts the dispatch created in Phase 2
      const acceptRes = await request(app)
        .post(`/api/v1/drivers/trips/${createdEmergencyId}/accept`)
        .set('Authorization', `Bearer ${driverToken}`);

      expect(acceptRes.status).toBe(200);
      expect(acceptRes.body.data.emergency.assignedDriverId).toBe(driverUser.id);
      expect(acceptRes.body.data.emergency.status).toBe('ASSIGNED');

      // 3. Driver progresses milestone: EN_ROUTE
      const enRouteRes = await request(app)
        .patch(`/api/v1/drivers/me/trips/${createdEmergencyId}/status`)
        .set('Authorization', `Bearer ${driverToken}`)
        .send({
          status: 'EN_ROUTE',
          latitude: 28.5360,
          longitude: 77.2885,
        });

      expect(enRouteRes.status).toBe(200);
      expect(enRouteRes.body.data.trip.status).toBe('EN_ROUTE');

      // 4. Driver progresses milestone: PATIENT_ON_BOARD
      const onBoardRes = await request(app)
        .patch(`/api/v1/drivers/me/trips/${createdEmergencyId}/status`)
        .set('Authorization', `Bearer ${driverToken}`)
        .send({
          status: 'PATIENT_ON_BOARD',
          latitude: 28.5355,
          longitude: 77.2882,
        });

      expect(onBoardRes.status).toBe(200);
      expect(onBoardRes.body.data.trip.status).toBe('PATIENT_ON_BOARD');

      // 5. Driver progresses milestone: REACHED_HOSPITAL
      const hospitalRes = await request(app)
        .patch(`/api/v1/drivers/me/trips/${createdEmergencyId}/status`)
        .set('Authorization', `Bearer ${driverToken}`)
        .send({
          status: 'REACHED_HOSPITAL',
          latitude: testHospital.latitude,
          longitude: testHospital.longitude,
        });

      expect(hospitalRes.status).toBe(200);
      expect(hospitalRes.body.data.trip.status).toBe('REACHED_HOSPITAL');

      // 6. Driver completes trip
      const completeRes = await request(app)
        .patch(`/api/v1/drivers/me/trips/${createdEmergencyId}/status`)
        .set('Authorization', `Bearer ${driverToken}`)
        .send({
          status: 'COMPLETED',
        });

      expect(completeRes.status).toBe(200);
      expect(completeRes.body.data.trip.status).toBe('COMPLETED');

      // 7. Driver queries assigned trips history
      const historyRes = await request(app)
        .get('/api/v1/drivers/me/trips')
        .set('Authorization', `Bearer ${driverToken}`);

      expect(historyRes.status).toBe(200);
      expect(historyRes.body.data.trips.length).toBeGreaterThanOrEqual(1);
    });

    it('3. Driver Queries Hospital Directory with Live ICU Beds (/hospitals/nearby)', async () => {
      const res = await request(app)
        .get('/api/v1/hospitals/nearby?latitude=28.5355&longitude=77.2882&radiusKm=20')
        .set('Authorization', `Bearer ${driverToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.hospitals.length).toBeGreaterThanOrEqual(1);
      const nearest = res.body.data.hospitals[0];
      expect(nearest).toHaveProperty('availableIcuBeds');
      expect(nearest).toHaveProperty('emergencyPhone');
    });
  });

  // ============================================================================
  // PHASE 6 & 7: REAL-TIME SOCKET.IO & CROSS-APP WORKFLOW INTEGRATION
  // ============================================================================
  describe('Phase 6 & 7 — Real-Time Socket.IO & Cross-App Integration Workflows', () => {
    it('Workflow 1: Appointment & Prescription Cross-App Lifecycle', async () => {
      // 1. Patient requests consultation
      const futureSlot = new Date(Date.now() + 3 * 86400000);
      futureSlot.setHours(14, 0, 0, 0);

      const apptRes = await request(app)
        .post('/api/v1/appointments')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          doctorProfileId: doctorProfile.id,
          startTime: futureSlot.toISOString(),
          durationMinutes: 30,
          reason: 'Comprehensive follow-up assessment',
          mode: 'IN_PERSON',
        });

      expect(apptRes.status).toBe(201);
      const apptId = apptRes.body.data.appointment.id;

      // 2. Doctor confirms
      await request(app)
        .patch(`/api/v1/appointments/${apptId}/confirm`)
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({ doctorNotes: 'Confirmed by specialist' });

      // 3. Doctor completes & creates prescription
      await request(app)
        .patch(`/api/v1/appointments/${apptId}/complete`)
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({ doctorNotes: 'Consultation finished' });

      const rxRes = await request(app)
        .post('/api/v1/prescriptions')
        .set('Authorization', `Bearer ${doctorToken}`)
        .send({
          patientProfileId: patientProfile.id,
          appointmentId: apptId,
          diagnosis: 'Seasonal Bronchial Hyperresponsiveness',
          generalAdvice: 'Avoid allergen triggers and use air purifier.',
          items: [
            {
              medicineName: 'Salbutamol Inhaler 100mcg',
              dosage: '2 Puffs SOS',
              frequency: 'PRN (As needed)',
              durationDays: 30,
              instructions: 'Use only during acute wheezing attacks',
            },
          ],
        });

      expect(rxRes.status).toBe(201);

      // 4. Patient reads the authored prescription
      const patCheck = await request(app)
        .get(`/api/v1/prescriptions/patient/${patientProfile.id}`)
        .set('Authorization', `Bearer ${patientToken}`);

      expect(patCheck.status).toBe(200);
      const match = patCheck.body.data.prescriptions.find((p: any) => p.diagnosis.includes('Hyperresponsiveness'));
      expect(match).toBeDefined();
      expect(match.items[0].medicineName).toContain('Salbutamol');
    });

    it('Workflow 2: Emergency SOS Dispatch, Live GPS Radar & Bed Allocation Handover', async () => {
      // 1. Patient SOS
      const sosRes = await request(app)
        .post('/api/v1/emergency/sos')
        .set('Authorization', `Bearer ${patientToken}`)
        .send({
          latitude: 28.5355,
          longitude: 77.2882,
          pickupAddress: 'Sector 8 Market, New Delhi',
        });

      expect(sosRes.status).toBe(201);
      const emgId = sosRes.body.data.emergency.id;

      // 2. Paramedic Driver claims dispatch
      const claimRes = await request(app)
        .post(`/api/v1/drivers/trips/${emgId}/accept`)
        .set('Authorization', `Bearer ${driverToken}`);

      expect(claimRes.status).toBe(200);

      // 3. Driver streams moving GPS coordinates
      socketService.emitAmbulanceLocation(emgId, {
        emergencyId: emgId,
        latitude: 28.5358,
        longitude: 77.2884,
        speed: 42.5,
        etaMinutes: 4,
      });

      // 4. Paramedic marks REACHED_HOSPITAL
      await request(app)
        .patch(`/api/v1/drivers/me/trips/${emgId}/status`)
        .set('Authorization', `Bearer ${driverToken}`)
        .send({ status: 'REACHED_HOSPITAL' });

      // 5. Hospital admits incoming trauma patient to bed
      const admitRes = await request(app)
        .patch(`/api/v1/hospitals/${testHospital.id}/beds/${testBedId}`)
        .set('Authorization', `Bearer ${hospitalAdminToken}`)
        .send({
          status: BedStatus.OCCUPIED,
          occupiedByPatient: 'Audit Patient Ananya (Emergency Handover)',
          notes: 'Triaged directly from ambulance unit DL-01-AMB-5544',
        });

      expect(admitRes.status).toBe(200);
      expect(admitRes.body.data.bed.status).toBe(BedStatus.OCCUPIED);
    });

    it('Workflow 4: Wearable Telemetry & Device Capabilities', async () => {
      const capRes = await request(app)
        .get('/api/v1/wearables/capabilities')
        .set('Authorization', `Bearer ${patientToken}`);

      expect(capRes.status).toBe(200);
      expect(capRes.body.success).toBe(true);
      expect(capRes.body.data).toHaveProperty('modelName');
      expect(capRes.body.data.modelName).toBe('FireBoltt 182');
      expect(capRes.body.data.connectivity.bluetoothLowEnergy.supported).toBe(true);
    });
  });
});
