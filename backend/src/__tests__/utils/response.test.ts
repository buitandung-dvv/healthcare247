import { Response } from 'express';
import { ApiResponse } from '../../utils/response';

// Mock Response object
const createMockResponse = (): Partial<Response> => {
    const res: Partial<Response> = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    res.send = jest.fn().mockReturnValue(res);
    return res;
};

describe('ApiResponse Helper', () => {
    let mockRes: Partial<Response>;

    beforeEach(() => {
        mockRes = createMockResponse();
    });

    describe('success', () => {
        it('should send success response with data', () => {
            const data = { id: 1, name: 'Test' };
            ApiResponse.success(mockRes as Response, data);

            expect(mockRes.json).toHaveBeenCalledWith({
                success: true,
                data,
            });
        });

        it('should send success response with message', () => {
            ApiResponse.success(mockRes as Response, null, 'Operation successful');

            expect(mockRes.json).toHaveBeenCalledWith({
                success: true,
                message: 'Operation successful',
                data: null,
            });
        });
    });

    describe('created', () => {
        it('should send 201 created response', () => {
            const data = { id: 1 };
            ApiResponse.created(mockRes as Response, data, 'Resource created');

            expect(mockRes.status).toHaveBeenCalledWith(201);
            expect(mockRes.json).toHaveBeenCalledWith({
                success: true,
                message: 'Resource created',
                data,
            });
        });
    });

    describe('badRequest', () => {
        it('should send 400 bad request response', () => {
            ApiResponse.badRequest(mockRes as Response, 'Invalid input');

            expect(mockRes.status).toHaveBeenCalledWith(400);
            expect(mockRes.json).toHaveBeenCalledWith({
                success: false,
                message: 'Invalid input',
            });
        });
    });

    describe('unauthorized', () => {
        it('should send 401 unauthorized response', () => {
            ApiResponse.unauthorized(mockRes as Response);

            expect(mockRes.status).toHaveBeenCalledWith(401);
            expect(mockRes.json).toHaveBeenCalledWith({
                success: false,
                message: 'Unauthorized',
            });
        });

        it('should send 401 with custom message', () => {
            ApiResponse.unauthorized(mockRes as Response, 'Token expired');

            expect(mockRes.status).toHaveBeenCalledWith(401);
            expect(mockRes.json).toHaveBeenCalledWith({
                success: false,
                message: 'Token expired',
            });
        });
    });

    describe('notFound', () => {
        it('should send 404 not found response', () => {
            ApiResponse.notFound(mockRes as Response, 'User');

            expect(mockRes.status).toHaveBeenCalledWith(404);
            expect(mockRes.json).toHaveBeenCalledWith({
                success: false,
                message: 'User not found',
            });
        });
    });

    describe('serverError', () => {
        it('should send 500 server error response', () => {
            ApiResponse.serverError(mockRes as Response, 'Database connection failed');

            expect(mockRes.status).toHaveBeenCalledWith(500);
            expect(mockRes.json).toHaveBeenCalledWith({
                success: false,
                message: 'Database connection failed',
            });
        });

        it('should use default message', () => {
            ApiResponse.serverError(mockRes as Response);

            expect(mockRes.status).toHaveBeenCalledWith(500);
            expect(mockRes.json).toHaveBeenCalledWith({
                success: false,
                message: 'Internal server error',
            });
        });
    });
});
