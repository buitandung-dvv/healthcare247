# HealthCare App - Backend API Setup Guide

## Mô tả

Ứng dụng HealthCare sử dụng kiến trúc **Repository Pattern** để tách biệt logic truy cập dữ liệu khỏi business logic. Dữ liệu được lấy từ **SQL Server Database** thông qua một **REST API Server**.

## Kiến trúc

```
┌─────────────────┐     ┌──────────────────┐     ┌────────────────┐
│  Flutter App    │ ←→  │   REST API       │ ←→  │  SQL Server    │
│  (Frontend)     │     │   (Backend)      │     │  (Database)    │
└─────────────────┘     └──────────────────┘     └────────────────┘
        │                       │                       │
   Providers             Controllers              Tables
   Repositories          Services                 Views
   Models                DTOs                     Stored Procs
```

## Cấu trúc Database (Đa ngôn ngữ)

### Tables chính:

```sql
-- Languages table
CREATE TABLE languages (
    language_id INT PRIMARY KEY,
    language_code VARCHAR(10),
    language_name NVARCHAR(50)
);

-- Exercises table (base)
CREATE TABLE exercises (
    exercise_id INT PRIMARY KEY IDENTITY,
    slug VARCHAR(255),
    level VARCHAR(50),
    category VARCHAR(100),
    equipment VARCHAR(100),
    force VARCHAR(50),
    mechanic VARCHAR(50)
);

-- Exercise translations
CREATE TABLE exercise_translations (
    translation_id INT PRIMARY KEY IDENTITY,
    exercise_id INT FOREIGN KEY REFERENCES exercises(exercise_id),
    language_id INT FOREIGN KEY REFERENCES languages(language_id),
    name NVARCHAR(255),
    description NVARCHAR(MAX),
    instructions NVARCHAR(MAX) -- JSON array of steps
);

-- Recipes table (base)
CREATE TABLE recipes (
    recipe_id INT PRIMARY KEY IDENTITY,
    recipe_code VARCHAR(50),
    themealdb_id VARCHAR(50),
    category VARCHAR(100),
    area VARCHAR(100),
    image_url VARCHAR(500),
    youtube_url VARCHAR(500),
    tags VARCHAR(500)
);

-- Recipe translations
CREATE TABLE recipe_translations (
    translation_id INT PRIMARY KEY IDENTITY,
    recipe_id INT FOREIGN KEY REFERENCES recipes(recipe_id),
    language_id INT FOREIGN KEY REFERENCES languages(language_id),
    name NVARCHAR(255),
    instructions NVARCHAR(MAX)
);
```

## Backend API Endpoints

### Base URL: `http://localhost:5000/api`

### Exercises
```
GET    /exercises                    # Lấy danh sách exercises
GET    /exercises/{id}               # Lấy chi tiết exercise
GET    /exercises/muscles            # Lấy danh sách muscles
GET    /exercises/categories         # Lấy danh sách categories
GET    /exercises/search?q=...       # Tìm kiếm exercises

Query Parameters:
  - language_id: 1 (English) hoặc 2 (Vietnamese)
  - page: số trang
  - limit: số items mỗi trang
  - level: beginner, intermediate, expert
  - category: tên category
  - muscle: tên muscle
```

### Recipes
```
GET    /recipes                      # Lấy danh sách recipes
GET    /recipes/{id}                 # Lấy chi tiết recipe
GET    /recipes/categories           # Lấy danh sách categories
GET    /recipes/areas                # Lấy danh sách areas
GET    /recipes/search?q=...         # Tìm kiếm recipes

Query Parameters:
  - language_id: 1 (English) hoặc 2 (Vietnamese)
  - page: số trang
  - limit: số items mỗi trang
  - category: tên category
  - area: tên area
```

## Response Format

### Paginated Response:
```json
{
  "items": [...],
  "total_count": 100,
  "page": 1,
  "page_size": 20,
  "has_more": true
}
```

### Exercise Detail:
```json
{
  "exercise_id": 1,
  "slug": "3-4-sit-up",
  "level": "intermediate",
  "category": "strength",
  "equipment": "body only",
  "force": "pull",
  "mechanic": "compound",
  "name": "3/4 Sit-Up",
  "description": "...",
  "instructions": ["Step 1...", "Step 2..."],
  "primary_muscles": ["abdominals"],
  "secondary_muscles": ["obliques"],
  "images": ["url1", "url2"]
}
```

### Recipe Detail:
```json
{
  "recipe_id": 1,
  "recipe_code": "RCP001",
  "category": "Chicken",
  "area": "Vietnamese",
  "image_url": "...",
  "youtube_url": "...",
  "tags": "healthy,dinner",
  "name": "Phở Gà",
  "instructions": "...",
  "ingredients": [
    {"ingredient": "Chicken", "measure": "500g"},
    {"ingredient": "Rice noodles", "measure": "300g"}
  ],
  "nutrition_info": {
    "calories": 450,
    "protein": 35,
    "carbs": 55,
    "fat": 12
  }
}
```

## Cách triển khai Backend

### Option 1: Node.js + Express
```bash
npm init
npm install express mssql cors dotenv
```

### Option 2: ASP.NET Core
```bash
dotnet new webapi
dotnet add package Microsoft.Data.SqlClient
```

### Option 3: Python + FastAPI
```bash
pip install fastapi uvicorn pyodbc
```

## Cấu hình Flutter App

Cập nhật file `lib/core/network/api_config.dart`:

```dart
class ApiConfig {
  // Thay đổi baseUrl theo môi trường
  static const String baseUrl = 'http://YOUR_SERVER_IP:5000/api';
  
  // Hoặc cho development:
  // Android Emulator: http://10.0.2.2:5000/api
  // iOS Simulator: http://localhost:5000/api
  // Physical Device: http://YOUR_PC_IP:5000/api
}
```

## Lưu ý quan trọng

1. **Đa ngôn ngữ**: Luôn truyền `language_id` trong query parameters để lấy dữ liệu đúng ngôn ngữ.

2. **Pagination**: Sử dụng `page` và `limit` để tải dữ liệu theo trang, tránh tải quá nhiều dữ liệu cùng lúc.

3. **Caching**: Provider sử dụng caching để giảm số lượng API calls.

4. **Error Handling**: Repository xử lý exceptions và trả về thông báo lỗi phù hợp.

5. **Offline Support**: Có thể mở rộng bằng cách thêm local database (SQLite/Hive) để cache dữ liệu offline.

