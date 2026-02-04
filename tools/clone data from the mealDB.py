import requests
import pyodbc
import re
import time
from googletrans import Translator

# Khởi tạo Google Translator
TRANSLATOR = Translator()

# Cấu hình Database
server = 'localhost'
database = 'HeathCare'
connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};Trusted_Connection=yes'


def translate_text(text, max_retries=5):
    """Dịch văn bản bằng Google Translate với xử lý lỗi tốt hơn"""
    if not text or len(text.strip()) == 0:
        return text

    translator = TRANSLATOR  # Sử dụng biến local

    for attempt in range(max_retries):
        try:
            result = translator.translate(text, src='en', dest='vi')
            time.sleep(0.3)  # Tránh rate limit
            return result.text if result and result.text else text
        except Exception as e:
            error_msg = str(e).lower()

            # Nếu là timeout hoặc connection error, đợi lâu hơn
            if 'timeout' in error_msg or 'connection' in error_msg:
                wait_time = (attempt + 1) * 2  # 2s, 4s, 6s, 8s, 10s
                if attempt < max_retries - 1:
                    print(f"        ⏳ Timeout, thử lại sau {wait_time}s...")
                    time.sleep(wait_time)

                    # Tạo lại translator sau timeout
                    translator = Translator()
                    continue

            # Các lỗi khác
            if attempt < max_retries - 1:
                time.sleep(1)
                continue
            else:
                print(f"        ⚠️  Lỗi sau {max_retries} lần thử: {e}")
                return text

    return text


def create_slug(text):
    """Tạo slug từ text"""
    text = str(text).lower()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    return text.strip('-')


def get_meals_by_area(area):
    """Lấy danh sách món ăn theo khu vực"""
    url = f"https://www.themealdb.com/api/json/v1/1/filter.php?a={area}"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            return response.json().get('meals', [])
    except:
        pass
    return []


def get_meal_details(meal_id):
    """Lấy chi tiết món ăn"""
    url = f"https://www.themealdb.com/api/json/v1/1/lookup.php?i={meal_id}"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            meals = response.json().get('meals', [])
            return meals[0] if meals else None
    except:
        pass
    return None


def search_meals_by_name(query):
    """Tìm kiếm món ăn theo tên"""
    url = f"https://www.themealdb.com/api/json/v1/1/search.php?s={query}"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            return response.json().get('meals', []) or []
    except:
        pass
    return []


def parse_ingredients(meal):
    """Parse nguyên liệu từ meal data"""
    ingredients = []
    for i in range(1, 21):
        ingredient = meal.get(f'strIngredient{i}') or ''
        measure = meal.get(f'strMeasure{i}') or ''
        ingredient = ingredient.strip() if ingredient else ''
        measure = measure.strip() if measure else ''
        if ingredient and ingredient.lower() not in ['', 'null', 'none']:
            ingredients.append({
                'ingredient': ingredient,
                'measure': measure,
                'order': i
            })
    return ingredients


def split_text(text, max_length=4000):
    """Chia text nếu quá dài"""
    if len(text) <= max_length:
        return text
    return text[:max_length]


def insert_recipe_to_db(cursor, meal, lang_en_id, lang_vi_id):
    """Insert recipe vào database"""
    try:
        meal_name_en = meal['strMeal']
        recipe_code = create_slug(meal_name_en)

        # Kiểm tra đã tồn tại chưa
        cursor.execute("SELECT recipe_id FROM Recipes WHERE recipe_code = ?", (recipe_code,))
        if cursor.fetchone():
            return None

        # Insert Recipe
        cursor.execute("""
            INSERT INTO Recipes (
                recipe_code, themealdb_id, category, area, 
                image_url, thumbnail_url, youtube_url, source_url, tags
            )
            OUTPUT INSERTED.recipe_id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            recipe_code,
            meal.get('idMeal', ''),
            meal.get('strCategory', ''),
            meal.get('strArea', ''),
            meal.get('strMealThumb', ''),
            meal.get('strMealThumb', ''),
            meal.get('strYoutube', ''),
            meal.get('strSource', ''),
            meal.get('strTags', '')
        ))

        recipe_id = cursor.fetchone()[0]

        # Dịch tên món
        print(f"    📄 Dịch tên: {meal_name_en[:50]}...")
        meal_name_vi = translate_text(meal_name_en)

        # Dịch instructions
        instructions_en = meal.get('strInstructions', '')
        instructions_en_db = split_text(instructions_en, 4000)

        print(f"    📄 Dịch hướng dẫn ({len(instructions_en)} ký tự)...")

        # Chia nhỏ instructions để dịch tốt hơn
        if len(instructions_en) > 1000:
            sentences = instructions_en.split('. ')
            translated_sentences = []
            current_chunk = ""

            for sentence in sentences:
                if len(current_chunk) + len(sentence) < 500:
                    current_chunk += sentence + ". "
                else:
                    if current_chunk:
                        translated_sentences.append(translate_text(current_chunk))
                    current_chunk = sentence + ". "

            if current_chunk:
                translated_sentences.append(translate_text(current_chunk))

            instructions_vi = " ".join(translated_sentences)
        else:
            instructions_vi = translate_text(instructions_en)

        instructions_vi_db = split_text(instructions_vi, 4000)

        # Insert translations
        cursor.execute("""
            INSERT INTO Recipe_Translations (recipe_id, language_id, name, instructions)
            VALUES (?, ?, ?, ?)
        """, (recipe_id, lang_en_id, meal_name_en, instructions_en_db))

        cursor.execute("""
            INSERT INTO Recipe_Translations (recipe_id, language_id, name, instructions)
            VALUES (?, ?, ?, ?)
        """, (recipe_id, lang_vi_id, meal_name_vi, instructions_vi_db))

        # Insert ingredients
        ingredients = parse_ingredients(meal)
        if ingredients:
            print(f"    📄 Dịch {len(ingredients)} nguyên liệu...")

            for ing in ingredients:
                ingredient_en = ing['ingredient']
                measure_en = ing['measure']

                # Dịch nguyên liệu và đơn vị đo
                ingredient_vi = translate_text(ingredient_en)
                measure_vi = translate_text(measure_en) if measure_en else ''

                # Insert EN
                cursor.execute("""
                    INSERT INTO Recipe_Ingredients (
                        recipe_id, language_id, ingredient_name, measure, display_order
                    ) VALUES (?, ?, ?, ?, ?)
                """, (recipe_id, lang_en_id, ingredient_en, measure_en, ing['order']))

                # Insert VI
                cursor.execute("""
                    INSERT INTO Recipe_Ingredients (
                        recipe_id, language_id, ingredient_name, measure, display_order
                    ) VALUES (?, ?, ?, ?, ?)
                """, (recipe_id, lang_vi_id, ingredient_vi, measure_vi, ing['order']))

            print(f"    ✓ Đã dịch xong nguyên liệu")

        print(f"    ✅ EN: {meal_name_en}")
        print(f"    ✅ VI: {meal_name_vi}")
        return recipe_id

    except Exception as e:
        print(f"    ❌ Lỗi: {e}")
        return None


def main():
    print("=" * 70)
    print("🍳 IMPORT RECIPES VỚI GOOGLE TRANSLATE")
    print("=" * 70)

    try:
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()
        print("\n✅ Kết nối SQL Server thành công!")

        # Lấy language IDs
        cursor.execute("SELECT language_id FROM Languages WHERE code = 'en'")
        lang_en_id = cursor.fetchone()[0]
        cursor.execute("SELECT language_id FROM Languages WHERE code = 'vi'")
        lang_vi_id = cursor.fetchone()[0]

        print(f"🔍 Language IDs: EN={lang_en_id}, VI={lang_vi_id}")
        print("\n🤖 Sử dụng Google Translate (không từ điển)")
        print("=" * 70)

        success_count = 0

        # ============================================
        # 1. MÓN ĂN VIỆT NAM
        # ============================================
        print("\n🇻🇳 PHẦN 1: MÓN ĂN VIỆT NAM")
        print("-" * 70)

        vietnamese_keywords = ['pho', 'vietnamese', 'spring roll', 'banh mi', 'bun']
        vietnamese_meals_dict = {}

        for keyword in vietnamese_keywords:
            print(f"🔍 Tìm kiếm: '{keyword}'...")
            meals = search_meals_by_name(keyword)
            for meal in meals:
                vietnamese_meals_dict[meal['idMeal']] = meal

        print(f"🔍 Tìm kiếm theo area 'Vietnamese'...")
        vietnamese_area_meals = get_meals_by_area('Vietnamese')
        for meal in vietnamese_area_meals:
            vietnamese_meals_dict[meal['idMeal']] = meal

        vietnamese_meals = list(vietnamese_meals_dict.values())
        print(f"\n📊 Tìm thấy {len(vietnamese_meals)} món Việt Nam")
        print("-" * 70)

        vn_success = 0
        for idx, meal in enumerate(vietnamese_meals, 1):
            print(f"\n[{idx}/{len(vietnamese_meals)}] Đang xử lý...")
            meal_details = get_meal_details(meal['idMeal'])
            if meal_details:
                recipe_id = insert_recipe_to_db(cursor, meal_details, lang_en_id, lang_vi_id)
                if recipe_id:
                    vn_success += 1
                    success_count += 1
                else:
                    print(f"    ⚠️  Đã tồn tại trong database")

            if idx % 5 == 0:
                conn.commit()
                print(f"  💾 Đã commit batch {idx // 5}")

        conn.commit()
        print(f"\n✅ Đã import {vn_success}/{len(vietnamese_meals)} món Việt Nam")

        # ============================================
        # 2. MÓN ĂN QUỐC TẾ - TĂNG SỐ LƯỢNG
        # ============================================
        print("\n" + "=" * 70)
        print("🌍 PHẦN 2: MÓN ĂN QUỐC TẾ (TĂNG SỐ LƯỢNG)")
        print("=" * 70)

        # TĂNG SỐ LƯỢNG MÓN ĂN
        popular_areas = {
            'American': 30,  # tăng từ 15
            'British': 25,  # tăng từ 15
            'Canadian': 20,  # tăng từ 10
            'Chinese': 40,  # tăng từ 20
            'Italian': 40,  # tăng từ 20
            'Japanese': 40,  # tăng từ 20
            'Thai': 40,  # tăng từ 20
            'Indian': 30,  # tăng từ 15
            'French': 30,  # tăng từ 15
            'Greek': 20,  # tăng từ 10
            'Mexican': 30,  # tăng từ 15
            'Spanish': 25,  # tăng từ 10
            'Turkish': 20,  # tăng từ 10
            'Korean': 25,  # tăng từ 10
            'Moroccan': 15,  # MỚI
            'Polish': 15,  # MỚI
            'Russian': 15,  # MỚI
            'Jamaican': 15,  # MỚI
            'Portuguese': 15,  # MỚI
            'Egyptian': 15,  # MỚI
        }

        for area, limit in popular_areas.items():
            print(f"\n🍽️  {area.upper()}")
            print("-" * 70)

            meals = get_meals_by_area(area)

            if not meals:
                print(f"  ⚠️  Không tìm thấy món ăn")
                continue

            area_success = 0
            meals_to_process = meals[:limit]

            for idx, meal in enumerate(meals_to_process, 1):
                print(f"\n  [{idx}/{len(meals_to_process)}] Đang xử lý...")
                meal_details = get_meal_details(meal['idMeal'])
                if meal_details:
                    recipe_id = insert_recipe_to_db(cursor, meal_details, lang_en_id, lang_vi_id)
                    if recipe_id:
                        area_success += 1
                        success_count += 1
                    else:
                        print(f"    ⚠️  Đã tồn tại trong database")

                if idx % 5 == 0:
                    conn.commit()

            conn.commit()
            print(f"\n  ✅ Import {area_success}/{len(meals_to_process)} món {area}")

        # ============================================
        # HOÀN THÀNH
        # ============================================
        print("\n" + "=" * 70)
        print("🎉 HOÀN THÀNH IMPORT!")
        print("=" * 70)
        print(f"📊 Tổng số recipes đã import: {success_count}")
        print(f"🇻🇳 Món Việt Nam: {vn_success}")
        print(f"🌍 Món quốc tế: {success_count - vn_success}")
        print(f"🎯 Tăng gấp ~2 lần so với trước!")
        print("\n💡 Dữ liệu đã được import:")
        print("   ✓ Recipes: Công thức nấu ăn")
        print("   ✓ Recipe_Translations: Tên + hướng dẫn (EN + VI)")
        print("   ✓ Recipe_Ingredients: Nguyên liệu (EN + VI)")
        print("\n🔍 Truy vấn dữ liệu:")
        print("   SELECT * FROM vw_Recipes_Vietnamese")
        print("   SELECT * FROM vw_Recipe_Ingredients_Vietnamese WHERE recipe_id = 1")
        print("=" * 70)

    except Exception as e:
        print(f"\n❌ Lỗi: {e}")
        import traceback
        traceback.print_exc()

    finally:
        if 'conn' in locals():
            cursor.close()
            conn.close()
            print("\n🔒 Đã đóng kết nối database")


if __name__ == "__main__":
    main()