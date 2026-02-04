"""
Import Daily Foods từ daily_food_nutrition_dataset_VN.csv
Schema Optimized v2.0 - merged into Foods table with source='daily_food'
"""

import os
import csv
import pyodbc
from datetime import datetime

RESOURCES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "resources")
SERVER = 'localhost'
DATABASE = 'HeathCare'


def clean_value(value, value_type='string'):
    if value is None or value == '' or value == 'NULL':
        return None
    if value_type == 'float':
        clean = ''.join(c for c in str(value) if c.isdigit() or c in '.-')
        try:
            return float(clean) if clean else None
        except ValueError:
            return None
    if value_type == 'int':
        try:
            return int(float(str(value).replace(',', '')))
        except ValueError:
            return None
    return str(value).strip()


def main():
    print("=" * 60)
    print("📥 IMPORT DAILY FOODS (→ Foods table with source='daily_food')")
    print("=" * 60)
    
    conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes'
    csv_file = os.path.join(RESOURCES_DIR, "daily_food_nutrition_dataset_VN.csv")
    
    if not os.path.exists(csv_file):
        print(f"❌ File không tồn tại: {csv_file}")
        return
    
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    print("✅ Connected to SQL Server")
    
    # Get language IDs
    cursor.execute("SELECT language_id FROM Languages WHERE code = 'en'")
    lang_en = cursor.fetchone()[0]
    cursor.execute("SELECT language_id FROM Languages WHERE code = 'vi'")
    lang_vi = cursor.fetchone()[0]
    
    success = 0
    
    with open(csv_file, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for idx, row in enumerate(reader, 1):
            try:
                code = f"daily_{idx}"
                
                # Check if exists
                cursor.execute("SELECT food_id FROM Foods WHERE code = ?", (code,))
                if cursor.fetchone():
                    continue
                
                # Insert into Foods with source='daily_food'
                cursor.execute("""
                    INSERT INTO Foods (
                        code, source, calories, protein, fat, carbs, fiber, sugars,
                        cholesterol, sodium, meal_type, water_intake_ml, category_code
                    )
                    OUTPUT INSERTED.food_id
                    VALUES (?, 'daily_food', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    code,
                    clean_value(row.get('Calories (kcal)'), 'float'),
                    clean_value(row.get('Protein (g)'), 'float'),
                    clean_value(row.get('Fat (g)'), 'float'),
                    clean_value(row.get('Carbohydrates (g)'), 'float'),
                    clean_value(row.get('Fiber (g)'), 'float'),
                    clean_value(row.get('Sugars (g)'), 'float'),
                    clean_value(row.get('Cholesterol (mg)'), 'float'),
                    clean_value(row.get('Sodium (mg)'), 'float'),
                    clean_value(row.get('Meal_Type')),
                    clean_value(row.get('Water_Intake (ml)'), 'int') or 0,
                    clean_value(row.get('Category'))
                ))
                
                food_id = cursor.fetchone()[0]
                
                # Insert English translation
                name_en = clean_value(row.get('Food_Item'))
                category_en = clean_value(row.get('Category'))
                if name_en:
                    cursor.execute("""
                        INSERT INTO Food_Translations (food_id, language_id, name, category_name)
                        VALUES (?, ?, ?, ?)
                    """, (food_id, lang_en, name_en, category_en))
                
                # Insert Vietnamese translation
                name_vi = clean_value(row.get('Food_Item_VN'))
                category_vi = clean_value(row.get('Category_VN'))
                if name_vi:
                    cursor.execute("""
                        INSERT INTO Food_Translations (food_id, language_id, name, category_name)
                        VALUES (?, ?, ?, ?)
                    """, (food_id, lang_vi, name_vi, category_vi))
                
                success += 1
                
            except Exception as e:
                print(f"   Error row {idx}: {e}")
    
    conn.commit()
    
    # Verify
    cursor.execute("SELECT COUNT(*) FROM Foods WHERE source = 'daily_food'")
    total_daily = cursor.fetchone()[0]
    print(f"\n✅ Imported {success} daily foods")
    print(f"📊 Total Foods (daily_food): {total_daily}")
    
    # Show meal type distribution
    cursor.execute("""
        SELECT meal_type, COUNT(*) as cnt 
        FROM Foods 
        WHERE source = 'daily_food' AND meal_type IS NOT NULL
        GROUP BY meal_type 
        ORDER BY cnt DESC
    """)
    print("\n📊 By Meal Type:")
    for row in cursor.fetchall():
        print(f"   - {row[0]}: {row[1]}")
    
    cursor.close()
    conn.close()
    print("\n🔒 Done!")


if __name__ == "__main__":
    main()
