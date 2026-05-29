import { Router } from 'express';
import { trackingController } from '../controllers/tracking.controller';
import { authMiddleware } from '../middleware/auth';
import {
    validateBody,
    exerciseTrackingSchema,
    mealTrackingSchema,
    weightTrackingSchema,
    waterTrackingSchema
} from '../utils/schemas';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// Dashboard stats
router.get('/stats/daily', (req, res) => trackingController.getDailyStats(req, res));
router.get('/stats/weekly', (req, res) => trackingController.getWeeklyStats(req, res));

// Exercise tracking
router.get('/exercises', (req, res) => trackingController.getExerciseTracking(req, res));
router.post('/exercises', validateBody(exerciseTrackingSchema), (req, res) => trackingController.logExercise(req, res));
router.delete('/exercises/:id', (req, res) => trackingController.deleteExerciseTracking(req, res));

// Meal tracking
router.get('/meals', (req, res) => trackingController.getMealTracking(req, res));
router.post('/meals', validateBody(mealTrackingSchema), (req, res) => trackingController.logMeal(req, res));
router.delete('/meals/:id', (req, res) => trackingController.deleteMealTracking(req, res));

// Weight tracking
router.get('/weight', (req, res) => trackingController.getWeightHistory(req, res));
router.post('/weight', validateBody(weightTrackingSchema), (req, res) => trackingController.logWeight(req, res));
router.delete('/weight/:id', (req, res) => trackingController.deleteWeightTracking(req, res));

// Water tracking
router.get('/water', (req, res) => trackingController.getWaterHistory(req, res));
router.get('/water/daily', (req, res) => trackingController.getDailyWaterIntake(req, res));
router.get('/water/weekly', (req, res) => trackingController.getWeeklyWaterSummary(req, res));
router.post('/water', validateBody(waterTrackingSchema), (req, res) => trackingController.logWater(req, res));
router.delete('/water/:id', (req, res) => trackingController.deleteWaterTracking(req, res));

export default router;
