type LogLevel = 'info' | 'warn' | 'error' | 'debug';

function formatLog(level: LogLevel, message: string, context?: unknown): string {
  const timestamp = new Date().toISOString();
  const contextStr = context ? ` | ${JSON.stringify(context)}` : '';
  return `[${timestamp}] [${level.toUpperCase()}] ${message}${contextStr}`;
}

export const logger = {
  info: (message: string, context?: unknown) => {
    console.log(formatLog('info', message, context));
  },
  warn: (message: string, context?: unknown) => {
    console.warn(formatLog('warn', message, context));
  },
  error: (message: string, context?: unknown) => {
    console.error(formatLog('error', message, context));
  },
  debug: (message: string, context?: unknown) => {
    if (process.env.NODE_ENV !== 'production') {
      console.debug(formatLog('debug', message, context));
    }
  },
};
