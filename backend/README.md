# Healthcare API Backend

Backend API cho ứng dụng Healthcare được xây dựng với Node.js, Express và TypeScript.

## 🚀 Cài đặt

### 1. Cài đặt dependencies

```bash
cd backend
npm install
```

### 2. Cấu hình môi trường

Copy file `.env.example` thành `.env` và cập nhật các giá trị:

```bash
cp .env.example .env
```

Các biến môi trường quan trọng:

```env
# Server
PORT=5000
NODE_ENV=development

# Database (SQL Server)
DB_SERVER=localhost
DB_PORT=1433
DB_DATABASE=HeathCare
DB_USER=sa
DB_PASSWORD=your_password

# JWT
JWT_SECRET=your_secret_key
JWT_EXPIRES_IN=7d
```

### 3. Chạy database script

Trước khi chạy backend, đảm bảo đã tạo database bằng file `HealthCare.sql`:

```sql
-- Chạy script trong SQL Server Management Studio
-- hoặc Azure Data Studio
```

### 4. Chạy server

**Development mode:**
```bash
npm run dev
```

**Production mode:**
```bash
npm run build
npm start
```

## 📚 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Đăng ký tài khoản |
| POST | `/api/auth/login` | Đăng nhập |
| GET | `/api/auth/me` | Lấy thông tin user hiện tại |
| PUT | `/api/auth/me` | Cập nhật thông tin user |

### Exercises
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/exercises` | Danh sách bài tập |
| GET | `/api/exercises/:id` | Chi tiết bài tập |
| GET | `/api/exercises/categories` | Danh mục bài tập |
| GET | `/api/exercises/levels` | Các cấp độ |
| GET | `/api/exercises/equipments` | Danh sách thiết bị |
| GET | `/api/exercises/muscles` | Danh sách nhóm cơ |

### Recipes
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/recipes` | Danh sách công thức |
| GET | `/api/recipes/:id` | Chi tiết công thức |
| GET | `/api/recipes/categories` | Danh mục công thức |
| GET | `/api/recipes/areas` | Vùng miền |
| GET | `/api/recipes/search` | Tìm kiếm công thức |

### Foods
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/foods` | Danh sách thực phẩm |
| GET | `/api/foods/:id` | Chi tiết thực phẩm |
| GET | `/api/foods/categories` | Danh mục thực phẩm |
| GET | `/api/foods/search` | Tìm kiếm thực phẩm |

### Meals (yêu cầu auth)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/meals` | Danh sách bữa ăn của user |
| GET | `/api/meals/:id` | Chi tiết bữa ăn |
| POST | `/api/meals/from-recipe` | Tạo bữa ăn từ công thức |
| POST | `/api/meals/custom` | Tạo bữa ăn tùy chỉnh |
| DELETE | `/api/meals/:id` | Xóa bữa ăn |

### Tracking (yêu cầu auth)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tracking/stats/daily` | Thống kê ngày |
| GET | `/api/tracking/stats/weekly` | Thống kê tuần |
| GET | `/api/tracking/exercises` | Lịch sử bài tập |
| POST | `/api/tracking/exercises` | Ghi nhận bài tập |
| DELETE | `/api/tracking/exercises/:id` | Xóa bài tập đã log |
| GET | `/api/tracking/meals` | Lịch sử bữa ăn |
| POST | `/api/tracking/meals` | Ghi nhận bữa ăn |
| DELETE | `/api/tracking/meals/:id` | Xóa bữa ăn đã log |

### Plans (yêu cầu auth)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/plans` | Danh sách kế hoạch |
| GET | `/api/plans/:id` | Chi tiết kế hoạch |
| POST | `/api/plans` | Tạo kế hoạch |
| DELETE | `/api/plans/:id` | Xóa kế hoạch |
| POST | `/api/plans/:id/details` | Thêm chi tiết kế hoạch |
| DELETE | `/api/plans/:id/details/:detailId` | Xóa chi tiết |

## 🔧 Query Parameters

### Pagination
- `page`: Số trang (mặc định: 1)
- `limit`: Số item/trang (mặc định: 20)

### Language
- `language_id`: 1 = English, 2 = Vietnamese

### Filters
**Exercises:**
- `level`: beginner, intermediate, expert
- `category`: powerlifting, strength, stretching, cardio...
- `equipment`: dumbbell, barbell, body only...
- `muscle`: chest, biceps, legs...
- `search`: Từ khóa tìm kiếm

**Recipes:**
- `category`: Beef, Chicken, Seafood...
- `area`: Vietnamese, Chinese, Italian...
- `search`: Từ khóa tìm kiếm

## 📝 Ví dụ Request

### Đăng ký
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john",
    "email": "john@example.com",
    "password": "123456"
  }'
```

### Lấy danh sách bài tập
```bash
curl "http://localhost:5000/api/exercises?language_id=2&level=beginner&limit=10"
```

### Log bài tập (với auth)
```bash
curl -X POST http://localhost:5000/api/tracking/exercises \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "exercise_id": 1,
    "duration_minutes": 30,
    "calories_burned": 250
  }'
```

## 🏗️ Cấu trúc thư mục

```
backend/
├── src/
│   ├── config/          # Cấu hình (database, env)
│   ├── controllers/     # Xử lý request/response
│   ├── middleware/      # Auth, error handling
│   ├── routes/          # Định nghĩa routes
│   ├── services/        # Business logic
│   ├── types/           # TypeScript types
│   └── index.ts         # Entry point
├── .env                 # Biến môi trường
├── .env.example         # Mẫu biến môi trường
├── package.json
├── tsconfig.json
└── README.md
```

## 🔐 Authentication

API sử dụng JWT (JSON Web Token) để xác thực. Sau khi đăng nhập, thêm token vào header:

```
Authorization: Bearer <your_token>
```

## 📄 License

MIT

