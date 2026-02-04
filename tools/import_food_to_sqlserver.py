import pandas as pd
import pyodbc
import os
import re
from deep_translator import GoogleTranslator

# Cấu hình kết nối SQL Server
server = 'localhost'
database = 'HeathCare'
connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};Trusted_Connection=yes'


def create_slug(text):
    """Tạo slug từ text"""
    text = str(text).lower()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    return text.strip('-')


def safe_float(value):
    """Chuyển đổi giá trị sang float an toàn"""
    if pd.isna(value):
        return None
    try:
        # Nếu là chuỗi, thử chuyển đổi
        if isinstance(value, str):
            value = value.strip()
            if value == '' or value.upper() == 'N/A':
                return None
            # Thay thế dấu phẩy bằng dấu chấm (nếu có)
            value = value.replace(',', '.')
        return float(value)
    except (ValueError, TypeError):
        return None


def translate_to_english(text):
    """Dịch text sang tiếng Anh"""
    try:
        translator = GoogleTranslator(source='vi', target='en')
        translated = translator.translate(str(text))
        return translated if translated else text
    except Exception as e:
        print(f"⚠️  Lỗi dịch '{text}': {str(e)}")
        return text


try:
    # Kết nối đến SQL Server
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()
    print("✅ Kết nối SQL Server thành công!")

    # Lấy language_id cho tiếng Anh và tiếng Việt
    cursor.execute("SELECT language_id FROM Languages WHERE code = 'en'")
    lang_en_id = cursor.fetchone()[0]

    cursor.execute("SELECT language_id FROM Languages WHERE code = 'vi'")
    lang_vi_id = cursor.fetchone()[0]

    print(f"📝 Language IDs: English={lang_en_id}, Vietnamese={lang_vi_id}")

    # Đọc file Excel
    excel_path = "D:/heath_care/tools/data.xlsx"

    if not os.path.exists(excel_path):
        print(f"❌ Không tìm thấy file: {excel_path}")
        exit(1)

    df = pd.read_excel(excel_path)
    print(f"✅ Đọc file Excel thành công! Tổng số dòng: {len(df)}")

    # Map tên cột
    column_mapping = {
        'TÊN THỨC ĂN': 'name_vi',
        'Calories (kcal)': 'calories',
        'Protein (g)': 'protein',
        'Fat (g)': 'fat',
        'Carbonhydrates (g)': 'carbs',
        'Chất xơ (g)': 'fiber',
        'Cholesterol (mg)': 'cholesterol',
        'Canxi (mg)': 'calcium',
        'Photpho (mg)': 'phosphorus',
        'Sắt (mg)': 'iron',
        'Natri (mg)': 'sodium',
        'Kali (mg)': 'potassium',
        'Beta Caroten (mcg)': 'beta_carotene',
        'Vitamin A (mcg)': 'vitamin_a',
        'Vitamin B1 (mg)': 'vitamin_b1',
        'Vitamin C (mg)': 'vitamin_c',
        'Loại': 'category'
    }

    df_renamed = df.rename(columns=column_mapping)

    print("🌐 Đang import thực phẩm với dịch tự động sang tiếng Anh...")
    print("💡 Tip: Cài đặt deep-translator nếu chưa có: pip install deep-translator")

    success_count = 0
    error_count = 0
    translation_success = 0

    for index, row in df_renamed.iterrows():
        try:
            name_vi = row.get('name_vi', '')

            # Bỏ qua nếu tên rỗng
            if pd.isna(name_vi) or str(name_vi).strip() == '':
                continue

            # Tạo code duy nhất cho thực phẩm
            food_code = create_slug(name_vi)

            # Kiểm tra xem food đã tồn tại chưa
            cursor.execute("SELECT food_id FROM Foods WHERE code = ?", (food_code,))
            existing = cursor.fetchone()

            if existing:
                print(f"⚠️  Bỏ qua (đã tồn tại): {name_vi}")
                continue

            # Dịch sang tiếng Anh
            name_en = translate_to_english(name_vi)
            if name_en != name_vi:
                translation_success += 1

            # Lấy category
            category_vi = row.get('category', '')
            if pd.isna(category_vi):
                category_code = 'other'
                category_vi = 'Khác'
                category_en = 'Other'
            else:
                category_code = create_slug(category_vi)
                # Dịch category sang tiếng Anh
                category_en = translate_to_english(category_vi)

            # Chuyển đổi tất cả các giá trị numeric sang float an toàn
            calories = safe_float(row.get('calories'))
            protein = safe_float(row.get('protein'))
            fat = safe_float(row.get('fat'))
            carbs = safe_float(row.get('carbs'))
            fiber = safe_float(row.get('fiber'))
            cholesterol = safe_float(row.get('cholesterol'))
            calcium = safe_float(row.get('calcium'))
            phosphorus = safe_float(row.get('phosphorus'))
            iron = safe_float(row.get('iron'))
            sodium = safe_float(row.get('sodium'))
            potassium = safe_float(row.get('potassium'))
            beta_carotene = safe_float(row.get('beta_carotene'))
            vitamin_a = safe_float(row.get('vitamin_a'))
            vitamin_b1 = safe_float(row.get('vitamin_b1'))
            vitamin_c = safe_float(row.get('vitamin_c'))

            # 1. Insert vào bảng Foods (chỉ dữ liệu dinh dưỡng)
            cursor.execute("""
                INSERT INTO Foods (
                    code, calories, protein, fat, carbs,
                    fiber, cholesterol, calcium, phosphorus, iron,
                    sodium, potassium, beta_carotene, vitamin_a, vitamin_b1,
                    vitamin_c, category_code
                )
                OUTPUT INSERTED.food_id
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                food_code,
                calories,
                protein,
                fat,
                carbs,
                fiber,
                cholesterol,
                calcium,
                phosphorus,
                iron,
                sodium,
                potassium,
                beta_carotene,
                vitamin_a,
                vitamin_b1,
                vitamin_c,
                category_code
            ))

            food_id = cursor.fetchone()[0]

            # 2. Insert translation tiếng Anh
            cursor.execute("""
                INSERT INTO Food_Translations (food_id, language_id, name, category_name)
                VALUES (?, ?, ?, ?)
            """, (food_id, lang_en_id, name_en, category_en))

            # 3. Insert translation tiếng Việt
            cursor.execute("""
                INSERT INTO Food_Translations (food_id, language_id, name, category_name)
                VALUES (?, ?, ?, ?)
            """, (food_id, lang_vi_id, name_vi, category_vi))

            success_count += 1

            # Hiển thị tiến trình
            if success_count % 20 == 0:
                conn.commit()
                print(f"⏳ Đã import {success_count}/{len(df)} dòng...")

        except Exception as e:
            error_count += 1
            print(f"❌ Lỗi tại dòng {index + 2}: {str(e)}")
            print(f"   Dữ liệu: {row.get('name_vi', 'N/A')}")

    # Commit các dòng còn lại
    conn.commit()

    print("\n" + "=" * 70)
    print(f"✅ Hoàn thành import dữ liệu!")
    print(f"📊 Tổng số dòng: {len(df)}")
    print(f"✅ Thành công: {success_count}")
    print(f"❌ Lỗi: {error_count}")
    print(f"🌍 Dịch thành công: {translation_success}/{success_count}")
    print("\n📝 Cấu trúc đa ngôn ngữ:")
    print("   - Foods: Chứa dữ liệu dinh dưỡng + code định danh")
    print("   - Food_Translations: Tên theo từng ngôn ngữ")
    print("   - Hỗ trợ thêm ngôn ngữ mới mà không cần thay đổi cấu trúc!")
    print("=" * 70)

except pyodbc.Error as e:
    print(f"❌ Lỗi SQL Server: {e}")

except Exception as e:
    print(f"❌ Lỗi: {e}")
    import traceback
    traceback.print_exc()

finally:
    if 'conn' in locals():
        cursor.close()
        conn.close()
        print("\n🔒 Đã đóng kết nối SQL Server")