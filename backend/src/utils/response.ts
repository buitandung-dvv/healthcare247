import { Response } from 'express';

/**
 * Standardized API response helpers
 * Reduces boilerplate in controllers
 */
export const ApiResponse = {
    /**
     * Send success response (200)
     */
    success: <T>(res: Response, data?: T, message?: string): void => {
        res.json({
            success: true,
            ...(message && { message }),
            ...(data !== undefined && { data }),
        });
    },

    /**
     * Send created response (201)
     */
    created: <T>(res: Response, data?: T, message?: string): void => {
        res.status(201).json({
            success: true,
            message: message || 'Created successfully',
            ...(data !== undefined && { data }),
        });
    },

    /**
     * Send error response with custom status code
     */
    error: (res: Response, statusCode: number, message: string): void => {
        res.status(statusCode).json({
            success: false,
            message,
        });
    },

    /**
     * Send 400 Bad Request response
     */
    badRequest: (res: Response, message: string): void => {
        res.status(400).json({
            success: false,
            message,
        });
    },

    /**
     * Send 401 Unauthorized response
     */
    unauthorized: (res: Response, message?: string): void => {
        res.status(401).json({
            success: false,
            message: message || 'Unauthorized',
        });
    },

    /**
     * Send 404 Not Found response
     */
    notFound: (res: Response, resource?: string): void => {
        res.status(404).json({
            success: false,
            message: resource ? `${resource} not found` : 'Not found',
        });
    },

    /**
     * Send 500 Internal Server Error response
     */
    serverError: (res: Response, message?: string): void => {
        res.status(500).json({
            success: false,
            message: message || 'Internal server error',
        });
    },
};
