import { Request, Response } from 'express';
import { authService } from '../services/auth.service';
import { AuthRequest } from '../middleware/auth';
import { ApiResponse } from '../utils/response';

export class AuthController {
  // Register
  async register(req: Request, res: Response): Promise<void> {
    try {
      const result = await authService.register(req.body);
      ApiResponse.created(res, result, 'User registered successfully');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Registration failed';
      console.error('❌ Register error:', message, 'Body:', JSON.stringify(req.body, null, 2));
      ApiResponse.badRequest(res, message);
    }
  }

  // Login
  async login(req: Request, res: Response): Promise<void> {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        ApiResponse.badRequest(res, 'Email and password are required');
        return;
      }

      const result = await authService.login(email, password);
      ApiResponse.success(res, result, 'Login successful');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Login failed';
      console.error('❌ Login error:', message);
      ApiResponse.unauthorized(res, message);
    }
  }

  // Get current user
  async getMe(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const user = await authService.getUserById(req.userId);

      if (!user) {
        ApiResponse.notFound(res, 'User');
        return;
      }

      ApiResponse.success(res, user);
    } catch (error) {
      console.error('❌ Get me error:', error);
      ApiResponse.serverError(res, 'Failed to get user');
    }
  }

  // Update user
  async updateUser(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const user = await authService.updateUser(req.userId, req.body);

      if (!user) {
        ApiResponse.notFound(res, 'User');
        return;
      }

      ApiResponse.success(res, user, 'User updated successfully');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Update failed';
      console.error('❌ Update user error:', message);
      ApiResponse.badRequest(res, message);
    }
  }

  // Social login (Google/Facebook)
  async socialLogin(req: Request, res: Response): Promise<void> {
    try {
      const { provider, provider_id, email, name, photo_url } = req.body;

      if (!provider || !email) {
        ApiResponse.badRequest(res, 'Provider and email are required');
        return;
      }

      const result = await authService.socialLogin({
        provider,
        provider_id: provider_id || '',
        email,
        name: name || email.split('@')[0],
        photo_url,
      });

      ApiResponse.success(res, result, 'Social login successful');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Social login failed';
      console.error('❌ Social login error:', message);
      ApiResponse.badRequest(res, message);
    }
  }
}

export const authController = new AuthController();
