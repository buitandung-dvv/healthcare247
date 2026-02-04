import { Router } from 'express';
import { workoutSessionController } from '../controllers/workout-session.controller';
import { authMiddleware } from '../middleware/auth';
import { validateBody, startSessionSchema, updateExerciseProgressSchema } from '../utils/schemas';

const router = Router();

// Apply auth middleware to all routes
router.use(authMiddleware);

// Session management
router.post('/', validateBody(startSessionSchema), (req, res) => workoutSessionController.startSession(req, res));
router.get('/active', (req, res) => workoutSessionController.getActiveSession(req, res));
router.get('/history', (req, res) => workoutSessionController.getSessionHistory(req, res));
router.get('/:id', (req, res) => workoutSessionController.getSessionById(req, res));

// Session actions
router.put('/:id/complete', (req, res) => workoutSessionController.completeSession(req, res));
router.post('/:id/cancel', (req, res) => workoutSessionController.cancelSession(req, res));

// Progress updates
router.put('/:id/exercises/:exerciseId', validateBody(updateExerciseProgressSchema), (req, res) => workoutSessionController.updateExerciseProgress(req, res));

export default router;
