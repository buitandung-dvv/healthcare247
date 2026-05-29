// User Types
export interface User {
  user_id: number;
  username: string;
  password?: string;
  email: string;
  full_name?: string;
  gender?: string;
  date_of_birth?: Date;
  height?: number;
  weight?: number;
  goal?: string;
  body_goals?: string;
  activity_level?: string;
  preferred_language_id: number;
  onboarding_completed: boolean;
  created_at: Date;
}

export interface UserCreateDTO {
  username: string;
  password: string;
  email: string;
  full_name?: string;
  gender?: string;
  date_of_birth?: string;
  height?: number;
  weight?: number;
  goal?: string;
  preferred_language_id?: number;
}

export interface UserUpdateDTO {
  username?: string;
  email?: string;
  full_name?: string;
  gender?: string;
  date_of_birth?: string;
  height?: number;
  weight?: number;
  goal?: string;
  body_goals?: string;
  activity_level?: string;
  preferred_language_id?: number;
  onboarding_completed?: boolean;
}

// Exercise Types
export interface Exercise {
  exercise_id: number;
  slug: string;
  force?: string;
  level: string;
  mechanic?: string;
  equipment?: string;
  category: string;
  created_at: Date;
  name?: string;
  primary_muscles?: string[];
  secondary_muscles?: string[];
  instructions?: string[];
  images?: string[];
}

// Food Types
export interface Food {
  food_id: number;
  code: string;
  source?: string;
  meal_type?: string;
  name?: string;
  category_name?: string;
  calories?: number;
  protein?: number;
  fat?: number;
  carbs?: number;
  fiber?: number;
  cholesterol?: number;
  calcium?: number;
  phosphorus?: number;
  iron?: number;
  sodium?: number;
  potassium?: number;
  beta_carotene?: number;
  vitamin_a?: number;
  vitamin_b1?: number;
  vitamin_c?: number;
  water_intake_ml?: number;
  created_at: Date;
}

// Recipe Types
export interface Recipe {
  recipe_id: number;
  recipe_code: string;
  themealdb_id?: string;
  category?: string;
  area?: string;
  image_url?: string;
  thumbnail_url?: string;
  youtube_url?: string;
  source_url?: string;
  tags?: string;
  created_at: Date;
  name?: string;
  overview?: string;  // General description (non-step)
  instructions?: RecipeInstruction[];  // Step-by-step instructions
  ingredients?: RecipeIngredient[];
}

export interface RecipeInstruction {
  step_order: number;
  instruction: string;
}

export interface RecipeIngredient {
  ingredient_name: string;
  measure?: string;
  display_order: number;
}

// Favorite Types (Replaces Meals)
export interface FavoriteFood {
  user_id: number;
  food_id: number;
  notes?: string;
  created_at: Date;
  food?: Food;  // Joined data
}

export interface FavoriteRecipe {
  user_id: number;
  recipe_id: number;
  notes?: string;
  created_at: Date;
  recipe?: Recipe;  // Joined data
}

export interface FavoriteExercise {
  user_id: number;
  exercise_id: number;
  notes?: string;
  created_at: Date;
  exercise?: Partial<Exercise>;  // Joined data (subset of fields)
}

// Tracking Types
export interface ExerciseTracking {
  tracking_id?: number;
  user_id: number;
  exercise_id: number;
  tracked_at?: Date;
  duration?: number;
  sets?: number;
  reps?: number;
  weight?: number;
  calories_burned?: number;
  notes?: string;
  created_at?: Date;
  exercise_name?: string;
}

export interface MealTracking {
  tracking_id?: number;
  user_id: number;
  meal_id?: number;
  date?: Date;
  meal_type?: string;
  meal_name?: string;
  calories?: number;
  protein?: number;
  carbs?: number;
  fat?: number;
  quantity?: number;
  notes?: string;
  created_at?: Date;
}

export interface WeightTracking {
  tracking_id?: number;
  user_id: number;
  weight: number;
  notes?: string;
  tracked_at: Date;
}

export interface WaterTracking {
  tracking_id?: number;
  user_id: number;
  amount_ml: number;
  notes?: string;
  tracked_at: Date;
}

// Plan Types
export interface Plan {
  plan_id: number;
  user_id: number;
  plan_type?: string;
  description?: string;
  created_at: Date;
  details?: PlanDetail[];
}

export interface PlanDetail {
  plan_id: number;
  exercise_id?: number;
  recipe_id?: number;
  food_id?: number;
  exercise_name?: string;
  recipe_name?: string;
  food_name?: string;
  sets?: number;
  reps?: number;
  rest_duration?: number;
  order_index: number;
}

// Workout Session Types
export interface WorkoutSession {
  session_id: number;
  user_id: number;
  plan_id?: number;
  exercise_id?: number;
  name?: string;
  started_at: Date;
  completed_at?: Date;
  total_duration?: number;
  calories_burned?: number;
  status: 'in_progress' | 'completed' | 'cancelled';
  notes?: string;
  details?: WorkoutSessionDetail[];
  plan?: Plan;
  exercise?: Exercise;
}

export interface WorkoutSessionDetail {
  detail_id: number;
  session_id: number;
  exercise_id: number;
  target_sets: number;
  target_reps: number;
  sets_completed: number;
  reps_completed?: string;
  weight_used?: string;
  rest_duration: number;
  order_index: number;
  started_at?: Date;
  completed_at?: Date;
  notes?: string;
  exercise?: Exercise;
}

export interface CreateWorkoutSessionDTO {
  plan_id?: number;
  exercise_id?: number;
  name?: string;
}

export interface UpdateWorkoutSessionDetailDTO {
  sets_completed?: number;
  reps_completed?: string;
  weight_used?: string;
  notes?: string;
}

// API Response Types
export interface ApiResponse<T> {
  success: boolean;
  message?: string;
  data?: T;
  pagination?: Pagination;
}

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

// Auth Types
export interface LoginDTO {
  email: string;
  password: string;
}

export interface AuthResponse {
  user: Omit<User, 'password'>;
  token: string;
}

// Query Params
export interface PaginationParams {
  page?: number;
  limit?: number;
}

export interface ExerciseQueryParams extends PaginationParams {
  language_id?: number;
  level?: string;
  category?: string;
  equipment?: string;
  muscle?: string;
  search?: string;
}

export interface RecipeQueryParams extends PaginationParams {
  language_id?: number;
  category?: string;
  area?: string;
  search?: string;
}

export interface FoodQueryParams extends PaginationParams {
  language_id?: number;
  category?: string;
  source?: string;
  meal_type?: string;
  search?: string;
}

// Muscle Types
export interface Muscle {
  muscle_id: number;
  code: string;
  name?: string;
  description?: string;
}
