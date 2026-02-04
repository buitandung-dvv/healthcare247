import requests
import json

print("=" * 70)
print("🔍 KIỂM TRA CẤU TRÚC DỮ LIỆU TỪ THEMEALDB API")
print("=" * 70)

# Test 1: Lấy chi tiết 1 món ăn
print("\n📋 TEST 1: Lấy chi tiết món ăn (lookup by ID)")
print("-" * 70)

meal_id = "52772"  # Teriyaki Chicken Casserole
url = f"https://www.themealdb.com/api/json/v1/1/lookup.php?i={meal_id}"

try:
    response = requests.get(url, timeout=10)
    data = response.json()

    if data and data.get('meals'):
        meal = data['meals'][0]

        print(f"\n✅ Tên món: {meal.get('strMeal')}")
        print(f"📂 Category: {meal.get('strCategory')}")
        print(f"🌍 Area: {meal.get('strArea')}")
        print(f"🆔 ID: {meal.get('idMeal')}")

        print("\n📸 Media:")
        print(f"  - Image: {meal.get('strMealThumb')[:50]}...")
        print(f"  - YouTube: {meal.get('strYoutube')}")
        print(f"  - Source: {meal.get('strSource')}")

        print("\n🏷️  Tags:", meal.get('strTags'))

        print("\n📝 Instructions (first 200 chars):")
        instructions = meal.get('strInstructions', '')
        print(f"  {instructions[:200]}...")

        print("\n🥘 INGREDIENTS:")
        print("-" * 70)
        for i in range(1, 21):
            ingredient = meal.get(f'strIngredient{i}', '').strip()
            measure = meal.get(f'strMeasure{i}', '').strip()

            if ingredient and ingredient.lower() not in ['', 'null', 'none']:
                print(f"  {i}. {measure:20s} {ingredient}")

        print("\n\n🔑 TẤT CẢ CÁC TRƯỜNG DỮ LIỆU:")
        print("-" * 70)
        for key in sorted(meal.keys()):
            value = str(meal[key])
            if len(value) > 60:
                value = value[:60] + "..."
            print(f"  {key:25s} = {value}")

except Exception as e:
    print(f"❌ Lỗi: {e}")

# Test 2: Tìm món Việt Nam
print("\n\n" + "=" * 70)
print("🇻🇳 TEST 2: Tìm món ăn Việt Nam")
print("=" * 70)

try:
    url = "https://www.themealdb.com/api/json/v1/1/search.php?s=pho"
    response = requests.get(url, timeout=10)
    data = response.json()

    if data and data.get('meals'):
        print(f"\n✅ Tìm thấy {len(data['meals'])} món chứa 'pho':")
        for meal in data['meals']:
            print(f"  - {meal['strMeal']} ({meal['strArea']})")
    else:
        print("❌ Không tìm thấy món nào")

except Exception as e:
    print(f"❌ Lỗi: {e}")

# Test 3: Lấy món theo area
print("\n\n" + "=" * 70)
print("🌏 TEST 3: Lấy món theo area (Vietnamese)")
print("=" * 70)

try:
    url = "https://www.themealdb.com/api/json/v1/1/filter.php?a=Vietnamese"
    response = requests.get(url, timeout=10)
    data = response.json()

    if data and data.get('meals'):
        print(f"\n✅ Có {len(data['meals'])} món Việt Nam:")
        for meal in data['meals'][:5]:  # Chỉ hiển thị 5 món đầu
            print(f"  - {meal['strMeal']} (ID: {meal['idMeal']})")
    else:
        print("❌ Không có món Việt Nam trong database")

except Exception as e:
    print(f"❌ Lỗi: {e}")

# Phân tích cấu trúc
print("\n\n" + "=" * 70)
print("📊 PHÂN TÍCH SO SÁNH CẤU TRÚC")
print("=" * 70)

print("""
╔════════════════════════════════╦════════════════════════════════╗
║  THEMEALDB API FIELDS          ║  YOUR DATABASE STRUCTURE       ║
╠════════════════════════════════╬════════════════════════════════╣
║ idMeal                         ║ ✅ themealdb_id                ║
║ strMeal                        ║ ✅ Meal_Translations.name      ║
║ strCategory                    ║ ✅ Meals.category              ║
║ strArea                        ║ ✅ Meals.area                  ║
║ strInstructions                ║ ✅ Meal_Translations.instruc.. ║
║ strMealThumb                   ║ ✅ Meals.image_url             ║
║ strYoutube                     ║ ✅ Meals.youtube_url           ║
║ strSource                      ║ ✅ Meals.source_url            ║
║ strTags                        ║ ❌ THIẾU (có thể thêm)         ║
║ strIngredient1-20              ║ ✅ Meal_Food_Items.ingredie..  ║
║ strMeasure1-20                 ║ ✅ Meal_Food_Items.quantity +..║
╚════════════════════════════════╩════════════════════════════════╝

✅ CẤU TRÚC CỦA BẠN HOÀN TOÀN PHÙ HỢP!

📝 Lưu ý:
1. TheMealDB có 20 cặp (ingredient + measure) → lưu vào Meal_Food_Items
2. Measure là string (vd: "200g", "1 cup") → cần parse thành quantity + unit
3. Ingredient name là tiếng Anh → cần map với Foods table
4. Instructions có thể rất dài → nên cắt ngắn khi dịch sang tiếng Việt

🎯 Điểm mạnh của cấu trúc bạn:
✅ Đa ngôn ngữ (Meal_Translations)
✅ Linh hoạt với quantity + unit riêng biệt
✅ Có thể map ingredients với Foods để tính dinh dưỡng
✅ Lưu được ingredient_name gốc khi chưa map được

⚠️  Có thể cải thiện:
- Thêm cột 'tags' vào Meals (để lưu strTags)
- Thêm cột 'date_modified' để sync với TheMealDB
""")