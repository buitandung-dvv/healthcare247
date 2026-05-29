import { Router, Request, Response } from 'express';
import { favoritesController } from '../controllers/favorites.controller';
import { authMiddleware } from '../middleware/auth';
import { validateBody, addFavoriteFoodSchema, addFavoriteRecipeSchema, addFavoriteExerciseSchema } from '../utils/schemas';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// Get all favorites (foods + recipes + exercises)
router.get('/', (req: Request, res: Response) => favoritesController.getUserFavorites(req, res));

// Foods
router.get('/foods', (req: Request, res: Response) => favoritesController.getFavoriteFoods(req, res));
router.post('/foods', validateBody(addFavoriteFoodSchema), (req: Request, res: Response) => favoritesController.addFavoriteFood(req, res));
router.delete('/foods/:foodId', (req: Request, res: Response) => favoritesController.removeFavoriteFood(req, res));

// Recipes
router.get('/recipes', (req: Request, res: Response) => favoritesController.getFavoriteRecipes(req, res));
router.post('/recipes', validateBody(addFavoriteRecipeSchema), (req: Request, res: Response) => favoritesController.addFavoriteRecipe(req, res));
router.delete('/recipes/:recipeId', (req: Request, res: Response) => favoritesController.removeFavoriteRecipe(req, res));

// Exercises
router.get('/exercises', (req: Request, res: Response) => favoritesController.getFavoriteExercises(req, res));
router.post('/exercises', validateBody(addFavoriteExerciseSchema), (req: Request, res: Response) => favoritesController.addFavoriteExercise(req, res));
router.delete('/exercises/:exerciseId', (req: Request, res: Response) => favoritesController.removeFavoriteExercise(req, res));

export default router;
