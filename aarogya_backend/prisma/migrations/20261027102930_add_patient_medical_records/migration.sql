-- CreateEnum
CREATE TYPE "RecordType" AS ENUM ('LAB_REPORT', 'PRESCRIPTION', 'DISCHARGE_SUMMARY', 'VITAL_LOG', 'IMAGING_REPORT', 'VACCINATION', 'CONSULTATION_NOTE', 'OTHER');

-- AlterTable
ALTER TABLE "PatientProfile" ADD COLUMN     "address" TEXT,
ADD COLUMN     "allergies" TEXT;

-- CreateTable
CREATE TABLE "MedicalRecord" (
    "id" TEXT NOT NULL,
    "patientProfileId" TEXT NOT NULL,
    "recordType" "RecordType" NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "recordDate" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "documentMetadata" JSONB,
    "issuingDoctor" TEXT,
    "facilityName" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MedicalRecord_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "MedicalRecord_patientProfileId_idx" ON "MedicalRecord"("patientProfileId");

-- CreateIndex
CREATE INDEX "MedicalRecord_recordType_idx" ON "MedicalRecord"("recordType");

-- CreateIndex
CREATE INDEX "MedicalRecord_recordDate_idx" ON "MedicalRecord"("recordDate");

-- CreateIndex
CREATE INDEX "PatientProfile_userId_idx" ON "PatientProfile"("userId");

-- CreateIndex
CREATE INDEX "PatientProfile_abhaId_idx" ON "PatientProfile"("abhaId");

-- AddForeignKey
ALTER TABLE "MedicalRecord" ADD CONSTRAINT "MedicalRecord_patientProfileId_fkey" FOREIGN KEY ("patientProfileId") REFERENCES "PatientProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;
