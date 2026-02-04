import { Router } from 'express';
import { planController } from '../controllers/plan.controller';
import { authMiddleware } from '../middleware/auth';
import { validateBody, createPlanSchema, addPlanDetailSchema } from '../utils/schemas';

const router = Router();

// All routes require authentication
router.use(authMiddleware);

// Plans
router.get('/', (req, res) => planController.getUserPlans(req, res));
router.get('/:id', (req, res) => planController.getPlanById(req, res));
router.post('/', validateBody(createPlanSchema), (req, res) => planController.createPlan(req, res));
router.put('/:id', (req, res) => planController.updatePlan(req, res));
router.delete('/:id', (req, res) => planController.deletePlan(req, res));

// Plan details
router.post('/:id/details', validateBody(addPlanDetailSchema), (req, res) => planController.addPlanDetail(req, res));
router.delete('/:id/details', (req, res) => planController.clearPlanDetails(req, res)); // Clear all details
router.delete('/:id/details/:detailId', (req, res) => planController.deletePlanDetail(req, res));

export default router;
