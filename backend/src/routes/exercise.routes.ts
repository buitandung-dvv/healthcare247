import { Router } from 'express';
import { exerciseController } from '../controllers/exercise.controller';

const router = Router();

// Get filter options
router.get('/categories', (req, res) => exerciseController.getCategories(req, res));
router.get('/levels', (req, res) => exerciseController.getLevels(req, res));
router.get('/equipments', (req, res) => exerciseController.getEquipments(req, res));
router.get('/muscles', (req, res) => exerciseController.getMuscles(req, res));

// Get exercises
router.get('/', (req, res) => exerciseController.getExercises(req, res));
router.get('/:id', (req, res) => exerciseController.getExerciseById(req, res));

export default router;
