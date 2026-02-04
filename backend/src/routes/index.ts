import { Router } from 'express';
import authRoutes from './auth.routes';
import exerciseRoutes from './exercise.routes';
import recipeRoutes from './recipe.routes';
import foodRoutes from './food.routes';
import favoritesRoutes from './favorites.routes';
import trackingRoutes from './tracking.routes';
import planRoutes from './plan.routes';
import workoutSessionRoutes from './workout-session.routes';
import goalsRoutes from './goals.routes';

const router = Router();

// API Routes
router.use('/auth', authRoutes);
router.use('/exercises', exerciseRoutes);
router.use('/recipes', recipeRoutes);
router.use('/foods', foodRoutes);
router.use('/favorites', favoritesRoutes);
router.use('/tracking', trackingRoutes);
router.use('/plans', planRoutes);
router.use('/workout-sessions', workoutSessionRoutes);
router.use('/users', goalsRoutes);

// Health check
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Healthcare API is running',
    timestamp: new Date().toISOString(),
  });
});

export default router;
