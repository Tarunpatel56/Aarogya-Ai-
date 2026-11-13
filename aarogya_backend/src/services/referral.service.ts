import { PrismaClient } from '@prisma/client';
import { NotFoundError, BadRequestError } from '../utils/AppError';

const prisma = new PrismaClient();

export interface CreateReferralParams {
  patientProfileId: string;
  referringDoctorId: string;
  targetDoctorId?: string;
  targetSpecialty: string;
  urgencyLevel: 'ROUTINE' | 'URGENT' | 'EMERGENCY';
  clinicalSummary: string;
  attachedRecordIds?: string[];
}

export class ReferralService {
  /**
   * Create doctor-to-doctor referral
   */
  public async createReferral(params: CreateReferralParams): Promise<any> {
    const patient = await prisma.patientProfile.findUnique({
      where: { id: params.patientProfileId },
    });
    if (!patient) {
      throw new NotFoundError('Patient profile not found');
    }

    const referringDoctor = await prisma.doctorProfile.findUnique({
      where: { id: params.referringDoctorId },
    });
    if (!referringDoctor) {
      throw new NotFoundError('Referring doctor profile not found');
    }

    return prisma.doctorReferral.create({
      data: {
        patientProfileId: params.patientProfileId,
        referringDoctorId: params.referringDoctorId,
        targetDoctorId: params.targetDoctorId,
        targetSpecialty: params.targetSpecialty,
        urgencyLevel: params.urgencyLevel,
        clinicalSummary: params.clinicalSummary,
        attachedRecordIds: params.attachedRecordIds || [],
        status: 'PENDING',
      },
      include: {
        patientProfile: true,
        referringDoctor: true,
        targetDoctor: true,
      },
    });
  }

  /**
   * Get all referrals initiated by or assigned to a doctor
   */
  public async getDoctorReferrals(doctorId: string): Promise<{ sent: any[]; received: any[] }> {
    const sent = await prisma.doctorReferral.findMany({
      where: { referringDoctorId: doctorId },
      include: { patientProfile: true, targetDoctor: true },
      orderBy: { createdAt: 'desc' },
    });

    const received = await prisma.doctorReferral.findMany({
      where: { targetDoctorId: doctorId },
      include: { patientProfile: true, referringDoctor: true },
      orderBy: { createdAt: 'desc' },
    });

    return { sent, received };
  }

  /**
   * Specialist responds to consultation referral
   */
  public async respondToReferral(
    referralId: string,
    doctorId: string,
    status: 'ACCEPTED' | 'DECLINED' | 'COMPLETED',
    specialistNotes?: string
  ): Promise<any> {
    const ref = await prisma.doctorReferral.findUnique({
      where: { id: referralId },
    });
    if (!ref) {
      throw new NotFoundError('Referral record not found');
    }

    return prisma.doctorReferral.update({
      where: { id: referralId },
      data: {
        status,
        specialistNotes: specialistNotes || ref.specialistNotes,
      },
      include: {
        patientProfile: true,
        referringDoctor: true,
      },
    });
  }
}

export const referralService = new ReferralService();

