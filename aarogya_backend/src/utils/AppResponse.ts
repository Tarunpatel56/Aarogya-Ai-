import { Response } from 'express';

export class AppResponse {
  static success<T>(res: Response, data: T, message: string = 'Success', statusCode: number = 200) {
    return res.status(statusCode).json({
      success: true,
      message,
      data,
    });
  }

  static error(res: Response, message: string = 'Error', statusCode: number = 400, errors?: any) {
    return res.status(statusCode).json({
      success: false,
      message,
      ...(errors ? { errors } : {}),
    });
  }
}

