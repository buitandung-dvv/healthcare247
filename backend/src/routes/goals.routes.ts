import { Router } from 'express';
import { goalsController } from '../controllers/goals.controller';
import { authMiddleware } from '../middleware/auth';
import { validateBody, goalsSchema } from '../utils/schemas';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// GET /api/users/:userId/goals - Get user goals
router.get('/:userId/goals', (req, res) => goalsController.getUserGoals(req, res));

// PUT /api/users/:userId/goals - Update user goals
router.put('/:userId/goals', validateBody(goalsSchema), (req, res) => goalsController.updateUserGoals(req, res));

export default router;
