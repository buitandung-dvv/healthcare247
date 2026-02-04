import { Router } from 'express';
import { authController } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth';
import { validateBody, registerSchema, loginSchema, updateUserSchema } from '../utils/schemas';

const router = Router();

// Public routes
router.post('/register', validateBody(registerSchema), (req, res) => authController.register(req, res));
router.post('/login', validateBody(loginSchema), (req, res) => authController.login(req, res));
router.post('/social', (req, res) => authController.socialLogin(req, res));

// Protected routes
router.get('/me', authMiddleware, (req, res) => authController.getMe(req, res));
router.put('/me', authMiddleware, validateBody(updateUserSchema), (req, res) => authController.updateUser(req, res));

export default router;
