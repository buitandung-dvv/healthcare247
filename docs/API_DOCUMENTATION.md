
# HealthCare API Documentation
## Phản ánh cấu trúc database HeathCare.sql

---

## Database Schema Summary

### Languages (language_id: 1=English, 2=Vietnamese)
```sql
Languages: language_id, code, name, is_default
```

### Users
```sql
Users: user_id, username, password, email, gender, date_of_birth, 
       height, weight, goal, preferred_language_id
```

### Exercises
```sql
Exercises: exercise_id, slug, force, level, mechanic, equipment, category
Exercise_Translations: translation_id, exercise_id, language_id, name, description
ExercisePrimaryMuscles: id, exercise_id, muscle
ExerciseSecondaryMuscles: id, exercise_id, muscle
ExerciseInstructions: id, exercise_id, language_id, step_order, instruction
ExerciseImages: id, exercise_id, image_url
Muscles: muscle_id, code
Muscle_Translations: translation_id, muscle_id, language_id, name, description
```

### Foods
```sql
Foods: food_id, code, calories, protein, fat, carbs, fiber, ...vitamins...
Food_Translations: translation_id, food_id, language_id, name, description, category_name
```

### Recipes
```sql
Recipes: recipe_id, recipe_code, themealdb_id, category, area, image_url, 
         thumbnail_url, youtube_url, source_url, tags, is_public
Recipe_Translations: translation_id, recipe_id, language_id, name, instructions
Recipe_Ingredients: ingredient_id, recipe_id, language_id, ingredient_name, measure, display_order
```

### Meals (User's personal meals)
```sql
Meals: meal_id, meal_code, user_id, recipe_id, meal_type, category, area, ...
Meal_Translations: translation_id, meal_id, language_id, name, description, instructions
Meal_Food_Items: meal_food_item_id, meal_id, food_id, ingredient_name, quantity, unit, display_order
```

### Plans & Tracking
```sql
Plans: plan_id, user_id, plan_type, description
Plan_Details: detail_id, plan_id, day_of_week, exercise_id, meal_id
Exercise_Tracking: tracking_id, user_id, exercise_id, duration_minutes, calories_burned, date
Meal_Tracking: tracking_id, user_id, meal_id, date
```

---

## API Endpoints

### Base URL
```
http://localhost:5000/api
```

---

## 1. Authentication

### POST /auth/login
```json
Request:
{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "success": true,
  "token": "jwt_token_here",
  "user": {
    "user_id": 1,
    "username": "john_doe",
    "email": "user@example.com",
    "gender": "male",
    "date_of_birth": "1990-01-15",
    "height": 175.5,
    "weight": 70.0,
    "goal": "lose_weight",
    "preferred_language_id": 1
  }
}
```

### POST /auth/register
```json
Request:
{
  "username": "john_doe",
  "email": "user@example.com",
  "password": "password123",
  "gender": "male",
  "date_of_birth": "1990-01-15",
  "height": 175.5,
  "weight": 70.0,
  "goal": "lose_weight",
  "preferred_language_id": 1
}
```

---

## 2. Exercises

### GET /exercises
Lấy danh sách exercises với đa ngôn ngữ

```
Query Parameters:
  - language_id: 1 (English) | 2 (Vietnamese)
  - page: số trang (default: 1)
  - limit: số items/trang (default: 20)
  - level: beginner | intermediate | expert
  - category: powerlifting | strength | stretching | cardio | ...
  - equipment: dumbbell | barbell | body only | ...
  - muscle: abdominals | biceps | chest | ...
  - search: từ khóa tìm kiếm

Response:
{
  "items": [
    {
      "exercise_id": 1,
      "slug": "3-4-sit-up",
      "force": "pull",
      "level": "intermediate",
      "mechanic": "isolation",
      "equipment": "body only",
      "category": "strength",
      "name": "3/4 Sit-Up",  // Theo language_id
      "description": "...",   // Theo language_id
      "primary_muscles": ["abdominals"],
      "secondary_muscles": [],
      "instructions": ["Step 1...", "Step 2..."],  // Theo language_id
      "images": ["url1.jpg", "url2.jpg"]
    }
  ],
  "total_count": 100,
  "page": 1,
  "page_size": 20,
  "has_more": true
}
```

### GET /exercises/{id}
Lấy chi tiết exercise

### GET /exercises/muscles
Lấy danh sách muscles với translation
```json
Response:
{
  "items": [
    {
      "muscle_id": 1,
      "code": "abdominals",
      "name": "Cơ bụng",  // Theo language_id
      "description": "Nhóm cơ vùng bụng"
    }
  ]
}
```

### GET /exercises/categories
### GET /exercises/equipments

---

## 3. Recipes

### GET /recipes
```
Query Parameters:
  - language_id: 1 | 2
  - page, limit
  - category: Beef | Chicken | Dessert | ...
  - area: Vietnamese | Chinese | Italian | ...
  - search: từ khóa

Response:
{
  "items": [
    {
      "recipe_id": 1,
      "recipe_code": "MEAL001",
      "themealdb_id": "52772",
      "category": "Chicken",
      "area": "Vietnamese",
      "image_url": "https://...",
      "thumbnail_url": "https://...",
      "youtube_url": "https://...",
      "tags": "healthy,dinner",
      "name": "Phở Gà",  // Theo language_id
      "instructions": "...",  // Theo language_id
      "ingredients": [  // Theo language_id
        {
          "ingredient_id": 1,
          "ingredient_name": "Gà nguyên con",
          "measure": "1.5 kg",
          "display_order": 1
        }
      ]
    }
  ]
}
```

### GET /recipes/{id}
### GET /recipes/categories
### GET /recipes/areas

---

## 4. Foods

### GET /foods
```
Query Parameters:
  - language_id
  - page, limit
  - category_code
  - search

Response:
{
  "items": [
    {
      "food_id": 1,
      "code": "FOOD001",
      "calories": 250.5,
      "protein": 25.0,
      "fat": 10.0,
      "carbs": 15.0,
      "fiber": 2.5,
      "name": "Thịt gà",
      "description": "...",
      "category_name": "Thịt gia cầm"
    }
  ]
}
```

---

## 5. Meals (User's Personal)

### GET /meals
```
Query Parameters:
  - user_id (required)
  - language_id
  - meal_type: breakfast | lunch | dinner | snack
  - is_custom: true | false

Response: Danh sách meals của user
```

### POST /meals
Tạo meal mới (custom)

### POST /meals/from-recipe
Tạo meal từ recipe có sẵn (gọi sp_CreateMealFromRecipe)
```json
Request:
{
  "user_id": 1,
  "recipe_id": 5,
  "meal_type": "lunch"
}
```

---

## 6. Plans

### GET /plans
```
Query Parameters:
  - user_id

Response:
{
  "items": [
    {
      "plan_id": 1,
      "user_id": 1,
      "plan_type": "weekly",
      "description": "Kế hoạch giảm cân tuần 1",
      "details": [
        {
          "detail_id": 1,
          "day_of_week": 1,  // Monday
          "exercise_id": 5,
          "meal_id": 3
        }
      ]
    }
  ]
}
```

### POST /plans
### PUT /plans/{id}

---

## 7. Tracking

### GET /tracking/exercises
```
Query Parameters:
  - user_id
  - start_date
  - end_date

Response:
{
  "items": [
    {
      "tracking_id": 1,
      "user_id": 1,
      "exercise_id": 5,
      "duration_minutes": 30,
      "calories_burned": 250.5,
      "date": "2026-01-16"
    }
  ]
}
```

### POST /tracking/exercises
### GET /tracking/meals
### POST /tracking/meals

---

## 8. Dashboard

### GET /dashboard/{user_id}
Lấy tổng quan cho dashboard
```json
Response:
{
  "today_progress": {
    "calories_consumed": 1500,
    "calories_goal": 2000,
    "calories_burned": 300,
    "protein": 80,
    "protein_goal": 120,
    "carbs": 150,
    "carbs_goal": 200,
    "fat": 50,
    "fat_goal": 65,
    "workouts_completed": 1,
    "workouts_planned": 2,
    "meals_logged": 3
  },
  "weekly_progress": [
    {
      "date": "2026-01-10",
      "calories_consumed": 1800,
      "workouts_completed": 2
    },
    // ... 7 days
  ]
}
```

---

## Notes

1. **Đa ngôn ngữ**: Luôn truyền `language_id` để lấy dữ liệu đúng ngôn ngữ
2. **Pagination**: Sử dụng `page` và `limit` 
3. **Views**: Có thể sử dụng views có sẵn trong database:
   - `vw_Recipes_Vietnamese`
   - `vw_Recipe_Ingredients_Vietnamese`
   - `vw_User_Meals`
4. **Stored Procedures**: 
   - `sp_CreateMealFromRecipe` - Tạo meal từ recipe
   - `fn_GetMuscleName` - Lấy tên muscle theo ngôn ngữ

