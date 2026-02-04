import { config } from '../config';

type LogLevel = 'debug' | 'info' | 'warn' | 'error';

const LOG_COLORS = {
    debug: '\x1b[36m', // cyan
    info: '\x1b[32m',  // green
    warn: '\x1b[33m',  // yellow
    error: '\x1b[31m', // red
    reset: '\x1b[0m',
} as const;

const formatMessage = (level: LogLevel, message: string, data?: unknown): string => {
    const timestamp = new Date().toISOString();
    const color = LOG_COLORS[level];
    const reset = LOG_COLORS.reset;
    const prefix = `${color}[${timestamp}] [${level.toUpperCase()}]${reset}`;

    if (data !== undefined) {
        return `${prefix} ${message} ${JSON.stringify(data)}`;
    }
    return `${prefix} ${message}`;
};

const shouldLog = (level: LogLevel): boolean => {
    const levels: LogLevel[] = ['debug', 'info', 'warn', 'error'];
    const currentLevel = config.nodeEnv === 'production' ? 'info' : 'debug';
    return levels.indexOf(level) >= levels.indexOf(currentLevel);
};

export const logger = {
    debug: (message: string, data?: unknown): void => {
        if (shouldLog('debug')) {
            console.log(formatMessage('debug', message, data));
        }
    },

    info: (message: string, data?: unknown): void => {
        if (shouldLog('info')) {
            console.log(formatMessage('info', message, data));
        }
    },

    warn: (message: string, data?: unknown): void => {
        if (shouldLog('warn')) {
            console.warn(formatMessage('warn', message, data));
        }
    },

    error: (message: string, error?: unknown): void => {
        if (shouldLog('error')) {
            console.error(formatMessage('error', message, error));
        }
    },
};
