-- CreateEnum
CREATE TYPE "ConsultationMode" AS ENUM ('IN_PERSON', 'ONLINE');

-- CreateEnum
CREATE TYPE "AvailabilityStatus" AS ENUM ('AVAILABLE', 'UNAVAILABLE', 'BUSY', 'ON_LEAVE');

-- AlterTable
ALTER TABLE "DoctorProfile" ADD COLUMN     "bio" TEXT,
ADD COLUMN     "clinicAddress" TEXT,
ADD COLUMN     "consultationFee" DOUBLE PRECISION DEFAULT 0.0,
ADD COLUMN     "consultationModes" "ConsultationMode"[] DEFAULT ARRAY['IN_PERSON', 'ONLINE']::"ConsultationMode"[],
ADD COLUMN     "languages" TEXT[] DEFAULT ARRAY['English', 'Hindi']::TEXT[];

-- CreateTable
CREATE TABLE "DoctorAvailability" (
    "id" TEXT NOT NULL,
    "doctorProfileId" TEXT NOT NULL,
    "startTime" TIMESTAMP(3) NOT NULL,
    "endTime" TIMESTAMP(3) NOT NULL,
    "timeZone" TEXT NOT NULL DEFAULT 'Asia/Kolkata',
    "status" "AvailabilityStatus" NOT NULL DEFAULT 'AVAILABLE',
    "isRecurring" BOOLEAN NOT NULL DEFAULT false,
    "dayOfWeek" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "DoctorAvailability_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "DoctorAvailability_doctorProfileId_idx" ON "DoctorAvailability"("doctorProfileId");

-- CreateIndex
CREATE INDEX "DoctorAvailability_startTime_endTime_idx" ON "DoctorAvailability"("startTime", "endTime");

-- CreateIndex
CREATE INDEX "DoctorAvailability_status_idx" ON "DoctorAvailability"("status");

-- CreateIndex
CREATE INDEX "DoctorProfile_userId_idx" ON "DoctorProfile"("userId");

-- CreateIndex
CREATE INDEX "DoctorProfile_specialization_idx" ON "DoctorProfile"("specialization");

-- CreateIndex
CREATE INDEX "DoctorProfile_nmcRegistrationNumber_idx" ON "DoctorProfile"("nmcRegistrationNumber");

-- AddForeignKey
ALTER TABLE "DoctorAvailability" ADD CONSTRAINT "DoctorAvailability_doctorProfileId_fkey" FOREIGN KEY ("doctorProfileId") REFERENCES "DoctorProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
