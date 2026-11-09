# Aarogya Healthcare Ecosystem — Backend Service

A high-performance, modular backend foundation built for the **Aarogya Healthcare Ecosystem**, serving:
- **Aarogya AI**: Patient telemetry, AI diagnostics, and health monitoring
- **Aarogya HealthPro**: Doctor consultations, emergency triage, hospital admission, and vitals telemetry
- **Aarogya Rapid**: Ambulance dispatch, emergency trip management, and live GPS routing

---

## 🛠 Tech Stack

- **Runtime**: [Node.js](https://nodejs.org/) (v24+)
- **Language**: [TypeScript](https://www.typescriptlang.org/) (Strict mode)
- **Framework**: [Express.js](https://expressjs.com/)
- **ORM / Database**: [Prisma](https://www.prisma.io/) with [PostgreSQL](https://www.postgresql.org/) (v18)
- **Security & Utilities**: Helmet, CORS, Morgan, Zod validation
- **Testing**: Vitest & Supertest

---

## 📁 Project Structure

```text
aarogya_backend/
├── prisma/
│   └── schema.prisma         # Prisma data schema & generator
├── src/
│   ├── config/
│   │   ├── env.ts            # Validated environment configuration (Zod)
│   │   └── prisma.ts         # Prisma client & live DB health check
│   ├── middleware/
│   │   ├── errorHandler.ts   # Centralized error handler
│   │   ├── notFoundHandler.ts# 404 not found handler
│   │   └── validateRequest.ts# Zod request validation middleware
│   ├── routes/
│   │   ├── health.routes.ts  # /health endpoint (accurate system status)
│   │   └── index.ts          # Central API router (/api/v1)
│   ├── utils/
│   │   ├── AppError.ts       # Standardized application error hierarchy
│   │   └── logger.ts         # Structured logging utility
│   ├── app.ts                # Express application setup & middleware chain
│   └── server.ts             # HTTP server bootstrap & graceful shutdown
├── tests/
│   └── health.test.ts        # Automated integration tests
├── .env.example              # Placeholder environment template
├── .gitignore                # Excludes secrets, credentials, and artifacts
├── package.json              # Dependencies and lifecycle scripts
├── tsconfig.json             # Strict TypeScript configuration
└── README.md                 # Setup and operational instructions
```

---

## 🚀 Getting Started

### 1. Prerequisites

- **Node.js**: v20 or higher (v24.14.0 tested)
- **npm**: v10 or higher (v11.6.1 tested)
- **PostgreSQL**: PostgreSQL 18 service running locally or accessible via network

### 2. Configure Environment Variables

Copy the `.env.example` template to `.env`:

```bash
cp .env.example .env
```

Edit `.env` and set your actual PostgreSQL credentials:

```ini
PORT=5000
NODE_ENV=development
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/aarogya_db?schema=public"
CORS_ORIGIN="*"
```

> **Security Note:** Never commit your `.env` file. It is safely ignored by `.gitignore`.

### 3. Generate Prisma Client

```bash
npm run prisma:generate
```

### 4. Running the Development Server

Start the development server with live reload:

```bash
npm run dev
```

The server will start on `http://localhost:5000`.

### 5. Running Production Build

```bash
# Build TypeScript
npm run build

# Start production server
npm start
```

---

## 🩺 System Health Check

The service includes an accurate, non-blocking health check endpoint at `/health`:

```bash
curl http://localhost:5000/health
```

### Example Response (Database unconfigured / pending setup):
```json
{
  "success": true,
  "status": "degraded",
  "timestamp": "2026-10-27T09:01:59.317Z",
  "uptimeSeconds": 15,
  "environment": "development",
  "version": "1.0.0",
  "services": {
    "api": {
      "status": "up"
    },
    "database": {
      "status": "disconnected",
      "message": "DATABASE_URL is not configured or contains placeholder credentials"
    }
  }
}
```

### Example Response (Database connected):
```json
{
  "success": true,
  "status": "healthy",
  "timestamp": "2026-10-27T09:05:00.000Z",
  "uptimeSeconds": 120,
  "environment": "development",
  "version": "1.0.0",
  "services": {
    "api": {
      "status": "up"
    },
    "database": {
      "status": "connected",
      "latencyMs": 4
    }
  }
}
```

---

## 🧪 Running Tests

Execute the automated test suite with Vitest:

```bash
npm test
```
