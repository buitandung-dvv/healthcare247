# HealthCare App 🏥💪

Ứng dụng theo dõi và chăm sóc sức khỏe đa ngôn ngữ (English/Vietnamese) được xây dựng bằng Flutter.

## ✨ Tính năng chính

### 🏠 Dashboard
- Tổng quan tiến độ hàng ngày
- Theo dõi calories, macros (protein, carbs, fat)
- Biểu đồ tiến độ tuần
- Quick actions: Log meal, Log workout, View plan

### 🏋️ Exercise Library
- Thư viện bài tập từ database
- Lọc theo level, category, equipment, muscle
- Hướng dẫn chi tiết với hình ảnh
- Hỗ trợ đa ngôn ngữ EN/VI

### 🍳 Recipe Library
- Công thức nấu ăn healthy
- Thông tin dinh dưỡng chi tiết
- Lọc theo category, area
- Hướng dẫn nấu ăn step-by-step

### 📊 Progress Tracking
- Theo dõi cân nặng
- Biểu đồ tiến độ
- Thành tựu và badges

### 👤 Profile
- Quản lý thông tin cá nhân
- Cài đặt mục tiêu
- Chuyển đổi ngôn ngữ

## 🏗️ Kiến trúc

```
lib/
├── core/
│   ├── constants/      # Colors, Sizes, Strings
│   ├── network/        # API Client, Config
│   ├── repositories/   # Data Repositories
│   └── theme/          # App Theme
├── data/
│   └── models/         # Data Models
├── providers/          # State Management (Provider)
├── screens/            # UI Screens
└── widgets/            # Reusable Widgets
    ├── cards/
    ├── charts/
    └── common/
```

## 🔄 Luồng dữ liệu

```
UI (Screen) 
    ↓
Provider (Business Logic)
    ↓
Repository (Data Access)
    ↓
API Client (HTTP Requests)
    ↓
Backend API Server
    ↓
SQL Server Database
```

## 🚀 Bắt đầu

### Prerequisites
- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio / VS Code
- SQL Server (cho backend)

### Cài đặt

1. Clone repository:
```bash
git clone https://github.com/your-repo/healthcare-app.git
cd healthcare-app
```

2. Cài đặt dependencies:
```bash
flutter pub get
```

3. Chạy ứng dụng:
```bash
flutter run
```

### Cấu hình Backend

Xem hướng dẫn chi tiết tại: [docs/BACKEND_API_SETUP.md](docs/BACKEND_API_SETUP.md)

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
  dio: ^5.4.0
  cached_network_image: ^3.3.0
  fl_chart: ^0.66.0
  shared_preferences: ^2.2.2
```

## 🌐 Đa ngôn ngữ

Ứng dụng hỗ trợ 2 ngôn ngữ:
- 🇺🇸 English (default)
- 🇻🇳 Tiếng Việt

Dữ liệu exercises và recipes được lưu trong database với translations table riêng, cho phép dễ dàng mở rộng thêm ngôn ngữ mới.

## 📱 Screenshots

[Coming soon...]

## 🤝 Contributing

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 📧 Contact

Your Name - your.email@example.com

Project Link: [https://github.com/your-repo/healthcare-app](https://github.com/your-repo/healthcare-app)

