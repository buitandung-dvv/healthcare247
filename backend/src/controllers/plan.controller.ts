import { Response } from 'express';
import { planService } from '../services/plan.service';
import { AuthRequest } from '../middleware/auth';
import { ApiResponse } from '../utils/response';
import { parseIntSafe, parseIdParam } from '../utils/validation';

export class PlanController {
  // Get user plans
  async getUserPlans(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;
      const plans = await planService.getUserPlans(req.userId, languageId);
      ApiResponse.success(res, plans);
    } catch (error) {
      console.error('❌ Get user plans error:', error);
      ApiResponse.serverError(res, 'Failed to get plans');
    }
  }

  // Get plan by ID
  async getPlanById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const planId = parseIdParam(req.params.id);
      if (!planId) {
        ApiResponse.badRequest(res, 'Invalid plan ID');
        return;
      }
      const languageId = parseIntSafe(req.query.language_id as string, 1) ?? 1;

      const plan = await planService.getPlanById(planId, languageId);

      if (!plan) {
        ApiResponse.notFound(res, 'Plan');
        return;
      }

      ApiResponse.success(res, plan);
    } catch (error) {
      console.error('❌ Get plan by ID error:', error);
      ApiResponse.serverError(res, 'Failed to get plan');
    }
  }

  // Create plan
  async createPlan(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const { name, plan_type, description, schedule_days } = req.body;
      const plan = await planService.createPlan(req.userId, plan_type, description, name, schedule_days);
      ApiResponse.created(res, plan, 'Plan created successfully');
    } catch (error) {
      console.error('❌ Create plan error:', error);
      ApiResponse.serverError(res, 'Failed to create plan');
    }
  }

  // Add detail to plan
  async addPlanDetail(req: AuthRequest, res: Response): Promise<void> {
    try {
      const planId = parseIdParam(req.params.id);
      if (!planId) {
        ApiResponse.badRequest(res, 'Invalid plan ID');
        return;
      }

      const {
        exercise_id,
        recipe_id,
        sets,
        reps,
        rest_duration,
        order_index
      } = req.body;

      const detail = await planService.addPlanDetail(
        planId,
        exercise_id,
        recipe_id,
        sets,
        reps,
        rest_duration,
        order_index
      );

      ApiResponse.created(res, detail, 'Plan detail added successfully');
    } catch (error) {
      console.error('❌ Add plan detail error:', error);
      ApiResponse.serverError(res, 'Failed to add plan detail');
    }
  }

  // Delete plan detail
  async deletePlanDetail(req: AuthRequest, res: Response): Promise<void> {
    try {
      const detailId = parseIdParam(req.params.detailId);
      if (!detailId) {
        ApiResponse.badRequest(res, 'Invalid detail ID');
        return;
      }

      const deleted = await planService.deletePlanDetail(detailId);

      if (!deleted) {
        ApiResponse.notFound(res, 'Plan detail');
        return;
      }

      res.status(204).send();
    } catch (error) {
      console.error('❌ Delete plan detail error:', error);
      ApiResponse.serverError(res, 'Failed to delete plan detail');
    }
  }

  // Delete plan
  async deletePlan(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const planId = parseIdParam(req.params.id);
      if (!planId) {
        ApiResponse.badRequest(res, 'Invalid plan ID');
        return;
      }

      const deleted = await planService.deletePlan(planId, req.userId);

      if (!deleted) {
        ApiResponse.notFound(res, 'Plan');
        return;
      }

      res.status(204).send();
    } catch (error) {
      console.error('❌ Delete plan error:', error);
      ApiResponse.serverError(res, 'Failed to delete plan');
    }
  }

  // Update plan
  async updatePlan(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const planId = parseIdParam(req.params.id);
      if (!planId) {
        ApiResponse.badRequest(res, 'Invalid plan ID');
        return;
      }

      const { name, description, schedule_days } = req.body;
      const updated = await planService.updatePlan(planId, req.userId, {
        name,
        description,
        scheduleDays: schedule_days
      });

      if (!updated) {
        ApiResponse.notFound(res, 'Plan');
        return;
      }

      ApiResponse.success(res, updated, 'Plan updated successfully');
    } catch (error) {
      console.error('❌ Update plan error:', error);
      ApiResponse.serverError(res, 'Failed to update plan');
    }
  }

  // Clear all plan details
  async clearPlanDetails(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.userId) {
        ApiResponse.unauthorized(res);
        return;
      }

      const planId = parseIdParam(req.params.id);
      if (!planId) {
        ApiResponse.badRequest(res, 'Invalid plan ID');
        return;
      }

      await planService.clearPlanDetails(planId);
      res.status(204).send();
    } catch (error) {
      console.error('❌ Clear plan details error:', error);
      ApiResponse.serverError(res, 'Failed to clear plan details');
    }
  }
}

export const planController = new PlanController();
