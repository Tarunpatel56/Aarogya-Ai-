# Aarogya-Ai-

A centralized, real-time healthcare ecosystem connecting Patients, Doctors, and Ambulances with seamless discovery, routing, appointment scheduling, and wearable telemetry monitoring.

## Applications & Structure

1. **Aarogya Patient App (`aarogya/`)**:
   - Flutter + GetX application for patients.
   - Real-time PPG Heart Rate, SpO2, and Vitals monitoring via Bluetooth GATT wearable integration.
   - Geolocation-based nearest doctor and ambulance discovery.
   - Direct appointment booking, consultation routing, and emergency SOS requests.

2. **Aarogya Doctor App (`aarogya_healthpro/`)**:
   - Flutter + GetX clinical practice application.
   - Duty management (Active Online / Offline duty status).
   - Real-time appointment management queue and consultation fee configuration.
   - Comprehensive patient medical file viewer (live vitals, lab reports, demographics).

3. **Aarogya Ambulance App (`aarogya_rapid/`)**:
   - Flutter + GetX emergency response driver app.
   - Real-time GPS location telemetry streaming.
   - Targeted emergency SOS dispatch and acceptance routing.

4. **Shared Backend (`aarogya_backend/`)**:
   - Node.js + TypeScript + Express.
   - PostgreSQL database with Prisma ORM and PostGIS geospatial discovery.
   - Real-time WebSockets (Socket.IO) & Firebase Cloud Messaging (FCM).
   - Role-Based Access Control (RBAC) & Superadmin verification engine.

