import express, { Application } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';
import { env } from './config/env';
import { apiRoutes } from './routes';
import { healthRoutes } from './routes/health.routes';
import { notFoundHandler } from './middleware/notFoundHandler';
import { errorHandler } from './middleware/errorHandler';

export function createApp(): Application {
  const app = express();

  // Security headers middleware configured for cross-origin web client compatibility
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      crossOriginEmbedderPolicy: false,
    })
  );

  // CORS configuration: Dynamically reflect origin to satisfy credentials + allow web clients on localhost / mobile
  const corsOptions: cors.CorsOptions = {
    origin: (origin, callback) => {
      // Allow requests with no origin (curl, mobile apps) and all incoming web origins
      callback(null, true);
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: [
      'Content-Type',
      'Authorization',
      'X-Requested-With',
      'Accept',
      'Origin',
      'ngrok-skip-browser-warning',
    ],
    exposedHeaders: ['Content-Range', 'X-Content-Range'],
  };

  const corsMiddleware = cors(corsOptions);
  app.use(corsMiddleware);

  // Pre-flight handling for all routes
  app.options('*', corsMiddleware);

  // Request parsing middleware
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // HTTP request logging
  if (env.NODE_ENV !== 'test') {
    app.use(morgan(env.NODE_ENV === 'production' ? 'combined' : 'dev'));
  }

  // Primary health check endpoint at /health (Task 9)
  app.use('/health', healthRoutes);

  // Versioned and root API routes
  app.use('/api/v1', apiRoutes);
  app.use('/api', apiRoutes);

  // 404 handler for undefined routes
  app.use(notFoundHandler);

  // Centralized error handler
  app.use(errorHandler);

  return app;
}

export const app = createApp();
