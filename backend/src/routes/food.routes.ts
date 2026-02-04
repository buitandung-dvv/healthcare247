import { Router } from 'express';
import { foodController } from '../controllers/food.controller';

const router = Router();

// Get filter options
router.get('/categories', (req, res) => foodController.getCategories(req, res));

// Search
router.get('/search', (req, res) => foodController.searchFoods(req, res));

// Get foods
router.get('/', (req, res) => foodController.getFoods(req, res));
router.get('/:id', (req, res) => foodController.getFoodById(req, res));

export default router;
