import { Router } from 'express';
import { authController } from '../controllers/auth.controller';
import { validateRequest } from '../middleware/validateRequest';
import { authenticate } from '../middleware/auth.middleware';
import { authRateLimiter } from '../middleware/rateLimiter';
import {
  registerPatientSchema,
  registerDoctorSchema,
  registerHospitalAdminSchema,
  registerAmbulanceStaffSchema,
  loginSchema,
  refreshTokenSchema,
  logoutSchema,
  sendOtpSchema,
  verifyOtpSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
} from '../validation/auth.validation';

const router = Router();

// Public registration endpoints with rate-limiting & Zod schema validation
router.post(
  '/register/patient',
  authRateLimiter,
  validateRequest(registerPatientSchema),
  authController.registerPatient
);

router.post(
  '/register/doctor',
  authRateLimiter,
  validateRequest(registerDoctorSchema),
  authController.registerDoctor
);

router.post(
  '/register/hospital-admin',
  authRateLimiter,
  validateRequest(registerHospitalAdminSchema),
  authController.registerHospitalAdmin
);

router.post(
  '/register/ambulance-staff',
  authRateLimiter,
  validateRequest(registerAmbulanceStaffSchema),
  authController.registerAmbulanceStaff
);

// Login and token management
router.post(
  '/login',
  authRateLimiter,
  validateRequest(loginSchema),
  authController.login
);

router.post(
  '/refresh-token',
  authRateLimiter,
  validateRequest(refreshTokenSchema),
  authController.refreshToken
);

router.post(
  '/refresh',
  authRateLimiter,
  validateRequest(refreshTokenSchema),
  authController.refreshToken
);

// Phone OTP authentication
router.post(
  '/send-otp',
  authRateLimiter,
  validateRequest(sendOtpSchema),
  authController.sendOtp
);

router.post(
  '/verify-otp',
  authRateLimiter,
  validateRequest(verifyOtpSchema),
  authController.verifyOtp
);

// Forgot password
router.post(
  '/forgot-password',
  authRateLimiter,
  validateRequest(forgotPasswordSchema),
  authController.forgotPassword
);

router.post(
  '/reset-password',
  authRateLimiter,
  validateRequest(resetPasswordSchema),
  authController.resetPassword
);

router.post(
  '/logout',
  validateRequest(logoutSchema),
  authController.logout
);

// Authenticated session management
router.post(
  '/logout-all',
  authenticate,
  authController.logoutAll
);

router.get(
  '/me',
  authenticate,
  authController.getMe
);

export const authRoutes = router;
