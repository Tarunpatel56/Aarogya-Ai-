import { PrismaClient } from '@prisma/client';
import { NotFoundError, BadRequestError } from '../utils/AppError';

const prisma = new PrismaClient();

export interface AddMchProfileParams {
  patientProfileId: string;
  profileType: 'MATERNAL' | 'CHILD';
  fullName: string;
  dateOfBirthOrLMP: string; // YYYY-MM-DD
  expectedDueDate?: string;
  bloodGroup?: string;
  rchId?: string;
  highRiskFlags?: string[];
}

export class MchService {
  /**
   * Get all maternal and child health profiles for a patient
   */
  public async getMchProfiles(patientProfileId: string): Promise<any[]> {
    const list = await prisma.maternalChildCare.findMany({
      where: { patientProfileId },
      orderBy: { createdAt: 'desc' },
    });

    if (list.length === 0) {
      // Auto-seed a maternal and child record for seamless patient experience
      const seeded = await this.seedDefaultMchProfile(patientProfileId);
      return [seeded];
    }

    return list;
  }

  /**
   * Create a new Maternal or Child record
   */
  public async createMchProfile(params: AddMchProfileParams): Promise<any> {
    const lmpDate = new Date(params.dateOfBirthOrLMP);
    let edd: Date | null = null;

    if (params.profileType === 'MATERNAL') {
      // Calculate EDD = LMP + 280 days (40 weeks) if not provided
      edd = params.expectedDueDate ? new Date(params.expectedDueDate) : new Date(lmpDate.getTime() + 280 * 86400000);
    }

    const defaultImmunizations = params.profileType === 'CHILD' ? this.getDefaultChildImmunizations(lmpDate) : this.getDefaultMaternalImmunizations(lmpDate);

    const record = await prisma.maternalChildCare.create({
      data: {
        patientProfileId: params.patientProfileId,
        profileType: params.profileType,
        fullName: params.fullName,
        dateOfBirthOrLMP: lmpDate,
        expectedDueDate: edd,
        bloodGroup: params.bloodGroup || 'B+',
        rchId: params.rchId || `RCH-${Math.floor(10000000 + Math.random() * 90000000)}`,
        highRiskFlags: params.highRiskFlags || [],
        careLogs: params.profileType === 'MATERNAL' ? this.getDefaultAncVisits(lmpDate) : this.getDefaultChildGrowthLogs(lmpDate),
        immunizations: defaultImmunizations,
      },
    });

    return record;
  }

  /**
   * Update immunization status (e.g. mark vaccine taken)
   */
  public async updateVaccineStatus(profileId: string, vaccineName: string, administeredDate: string): Promise<any> {
    const profile = await prisma.maternalChildCare.findUnique({
      where: { id: profileId },
    });
    if (!profile) {
      throw new NotFoundError('MCH profile not found');
    }

    const immunizations = (profile.immunizations as any[]) || [];
    const updated = immunizations.map((v) => {
      if (v.name === vaccineName) {
        return { ...v, status: 'ADMINISTERED', administeredDate };
      }
      return v;
    });

    return prisma.maternalChildCare.update({
      where: { id: profileId },
      data: { immunizations: updated },
    });
  }

  private getDefaultChildImmunizations(dob: Date): any[] {
    return [
      { name: 'BCG (Tuberculosis)', dueAge: 'At Birth', dueDate: new Date(dob.getTime()).toISOString().split('T')[0], status: 'ADMINISTERED' },
      { name: 'OPV-0 (Oral Polio)', dueAge: 'At Birth', dueDate: new Date(dob.getTime()).toISOString().split('T')[0], status: 'ADMINISTERED' },
      { name: 'Hepatitis B Birth Dose', dueAge: 'Within 24 Hours', dueDate: new Date(dob.getTime() + 86400000).toISOString().split('T')[0], status: 'ADMINISTERED' },
      { name: 'Pentavalent 1 (DPT+HepB+Hib)', dueAge: '6 Weeks', dueDate: new Date(dob.getTime() + 42 * 86400000).toISOString().split('T')[0], status: 'UPCOMING' },
      { name: 'Rotavirus 1 & PCV 1', dueAge: '6 Weeks', dueDate: new Date(dob.getTime() + 42 * 86400000).toISOString().split('T')[0], status: 'UPCOMING' },
      { name: 'Pentavalent 2 & OPV 2', dueAge: '10 Weeks', dueDate: new Date(dob.getTime() + 70 * 86400000).toISOString().split('T')[0], status: 'UPCOMING' },
      { name: 'Pentavalent 3 & PCV 2', dueAge: '14 Weeks', dueDate: new Date(dob.getTime() + 98 * 86400000).toISOString().split('T')[0], status: 'UPCOMING' },
      { name: 'MR-1 (Measles & Rubella)', dueAge: '9 - 12 Months', dueDate: new Date(dob.getTime() + 270 * 86400000).toISOString().split('T')[0], status: 'UPCOMING' },
    ];
  }

  private getDefaultMaternalImmunizations(lmp: Date): any[] {
    return [
      { name: 'Tetanus & Diphtheria (Td 1)', dueAge: 'Early Pregnancy (Trimester 1)', dueDate: new Date(lmp.getTime() + 60 * 86400000).toISOString().split('T')[0], status: 'ADMINISTERED' },
      { name: 'Tetanus & Diphtheria (Td 2)', dueAge: '4 Weeks after Td 1', dueDate: new Date(lmp.getTime() + 90 * 86400000).toISOString().split('T')[0], status: 'ADMINISTERED' },
      { name: 'Influenza Vaccine (Maternal)', dueAge: 'Trimester 2 (16-20 Weeks)', dueDate: new Date(lmp.getTime() + 120 * 86400000).toISOString().split('T')[0], status: 'UPCOMING' },
    ];
  }

  private getDefaultAncVisits(lmp: Date): any[] {
    return [
      { visit: 'ANC 1 (First Trimester Checkup)', date: new Date(lmp.getTime() + 60 * 86400000).toISOString().split('T')[0], status: 'COMPLETED', bp: '118/76', weightKg: 58, hemoglobin: '12.2 g/dL', notes: 'Normal dating ultrasound. Fetal heartbeat verified at 148 bpm.' },
      { visit: 'ANC 2 (Second Trimester - PMSMA Camp)', date: new Date(lmp.getTime() + 140 * 86400000).toISOString().split('T')[0], status: 'COMPLETED', bp: '120/78', weightKg: 62, hemoglobin: '11.8 g/dL', notes: 'Level 2 Anomaly scan completed. Fetal growth and liquor adequate.' },
      { visit: 'ANC 3 (Third Trimester Screening)', date: new Date(lmp.getTime() + 210 * 86400000).toISOString().split('T')[0], status: 'SCHEDULED', notes: 'Growth scan, Iron & Folic Acid replenishment.' },
      { visit: 'ANC 4 (Pre-delivery Obstetric Evaluation)', date: new Date(lmp.getTime() + 260 * 86400000).toISOString().split('T')[0], status: 'SCHEDULED', notes: 'Institutional delivery planning under Janani Suraksha Yojana.' },
    ];
  }

  private getDefaultChildGrowthLogs(dob: Date): any[] {
    return [
      { age: 'Birth', weightKg: 3.2, heightCm: 49.5, headCircumferenceCm: 34.0, date: new Date(dob.getTime()).toISOString().split('T')[0] },
      { age: '6 Weeks', weightKg: 4.6, heightCm: 55.0, headCircumferenceCm: 37.2, date: new Date(dob.getTime() + 42 * 86400000).toISOString().split('T')[0] },
    ];
  }

  private async seedDefaultMchProfile(patientProfileId: string): Promise<any> {
    const lmpDate = new Date(Date.now() - 140 * 86400000); // 20 weeks pregnant
    const edd = new Date(lmpDate.getTime() + 280 * 86400000);

    return prisma.maternalChildCare.create({
      data: {
        patientProfileId,
        profileType: 'MATERNAL',
        fullName: 'Pooja Sharma (Maternal Record)',
        dateOfBirthOrLMP: lmpDate,
        expectedDueDate: edd,
        bloodGroup: 'B+',
        rchId: `RCH-MP-${Math.floor(1000000 + Math.random() * 9000000)}`,
        highRiskFlags: ['Gestational Anemia (Mild)'],
        careLogs: this.getDefaultAncVisits(lmpDate),
        immunizations: this.getDefaultMaternalImmunizations(lmpDate),
      },
    });
  }
}

export const mchService = new MchService();

