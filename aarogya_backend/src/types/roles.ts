import { Role as PrismaRole } from '@prisma/client';

/**
 * Aarogya Healthcare Ecosystem - Canonical User Roles
 * 
 * 1. PATIENT: Individual managing their own health, appointments, records, and AI diagnostics.
 * 2. HOSPITAL_ADMIN: Manages their specific hospital's profile, staff roster, and hospital appointments.
 * 3. DRIVER: Ambulance driver managing assigned emergency dispatches and trips.
 * 4. SUPER_ADMIN: Master platform administrator with full control over users, roles, and operational stats.
 * 
 * Note: Retains backward-compatible mapping with existing schema enums (PLATFORM_ADMIN, AMBULANCE_DRIVER, DOCTOR, PARAMEDIC).
 */
export const UserRoles = {
  PATIENT: 'PATIENT' as const,
  HOSPITAL_ADMIN: 'HOSPITAL_ADMIN' as const,
  DRIVER: 'DRIVER' as const,
  SUPER_ADMIN: 'SUPER_ADMIN' as const,
  DOCTOR: 'DOCTOR' as const,
  PARAMEDIC: 'PARAMEDIC' as const,
};

export type AppRole =
  | 'PATIENT'
  | 'HOSPITAL_ADMIN'
  | 'DRIVER'
  | 'SUPER_ADMIN'
  | 'DOCTOR'
  | 'PARAMEDIC'
  | 'PLATFORM_ADMIN'
  | 'AMBULANCE_DRIVER';

/**
 * Normalizes input role string to underlying database PrismaRole.
 */
export function toPrismaRole(role: string): PrismaRole {
  const normalized = role.trim().toUpperCase();
  if (normalized === 'SUPER_ADMIN' || normalized === 'PLATFORM_ADMIN') {
    return PrismaRole.PLATFORM_ADMIN;
  }
  if (normalized === 'DRIVER' || normalized === 'AMBULANCE_DRIVER') {
    return PrismaRole.AMBULANCE_DRIVER;
  }
  if (normalized === 'HOSPITAL_ADMIN') {
    return PrismaRole.HOSPITAL_ADMIN;
  }
  if (normalized === 'PATIENT') {
    return PrismaRole.PATIENT;
  }
  if (normalized === 'DOCTOR') {
    return PrismaRole.DOCTOR;
  }
  if (normalized === 'PARAMEDIC') {
    return PrismaRole.PARAMEDIC;
  }
  return normalized as PrismaRole;
}

/**
 * Converts database role to canonical user-facing role string.
 */
export function toCanonicalRole(role: PrismaRole | string): string {
  if (role === PrismaRole.PLATFORM_ADMIN || role === 'SUPER_ADMIN') {
    return 'SUPER_ADMIN';
  }
  if (role === PrismaRole.AMBULANCE_DRIVER || role === 'DRIVER') {
    return 'DRIVER';
  }
  return role.toString();
}

/**
 * Checks if a given role has Super Admin privileges.
 */
export function isSuperAdmin(role: PrismaRole | string): boolean {
  return role === PrismaRole.PLATFORM_ADMIN || role === 'SUPER_ADMIN';
}

/**
 * Checks if a given role has Driver privileges.
 */
export function isDriver(role: PrismaRole | string): boolean {
  return role === PrismaRole.AMBULANCE_DRIVER || role === 'DRIVER';
}

