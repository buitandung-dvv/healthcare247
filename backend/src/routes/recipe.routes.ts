import { Router } from 'express';
import { recipeController } from '../controllers/recipe.controller';

const router = Router();

// Get filter options
router.get('/categories', (req, res) => recipeController.getCategories(req, res));
router.get('/areas', (req, res) => recipeController.getAreas(req, res));

// Search
router.get('/search', (req, res) => recipeController.searchRecipes(req, res));

// Get recipes
router.get('/', (req, res) => recipeController.getRecipes(req, res));
router.get('/:id', (req, res) => recipeController.getRecipeById(req, res));

export default router;
