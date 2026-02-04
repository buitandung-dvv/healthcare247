"""
Import Foods từ nutrition_VN.csv
Schema Optimized v2.0 - merged Daily_Foods
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
    print("📥 IMPORT FOODS (nutrition_VN.csv)")
    print("=" * 60)
    
    conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes'
    csv_file = os.path.join(RESOURCES_DIR, "nutrition_VN.csv")
    
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
                # Generate code from ID or name
                code = f"food_{idx}"
                
                # Check if exists
                cursor.execute("SELECT food_id FROM Foods WHERE code = ?", (code,))
                if cursor.fetchone():
                    continue
                
                # Insert Foods with source='nutrition_vn'
                cursor.execute("""
                    INSERT INTO Foods (
                        code, source, calories, protein, fat, saturated_fat, carbs, fiber, sugars,
                        cholesterol, calcium, phosphorus, iron, sodium, potassium, magnesium,
                        zinc, copper, manganese, selenium, beta_carotene, vitamin_a, vitamin_a_rae,
                        vitamin_b1, vitamin_b6, vitamin_b12, vitamin_c, vitamin_d, vitamin_e, vitamin_k,
                        folate, niacin, riboflavin, pantothenic_acid, choline, water, alcohol, caffeine, ash,
                        category_code
                    )
                    OUTPUT INSERTED.food_id
                    VALUES (?, 'nutrition_vn', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    code,
                    clean_value(row.get('calories'), 'float'),
                    clean_value(row.get('protein'), 'float'),
                    clean_value(row.get('total_fat'), 'float'),
                    clean_value(row.get('saturated_fat'), 'float'),
                    clean_value(row.get('carbohydrate'), 'float'),
                    clean_value(row.get('fiber'), 'float'),
                    clean_value(row.get('sugars'), 'float'),
                    clean_value(row.get('cholesterol'), 'float'),
                    clean_value(row.get('calcium'), 'float'),
                    clean_value(row.get('phosphorus'), 'float'),
                    clean_value(row.get('iron'), 'float'),
                    clean_value(row.get('sodium'), 'float'),
                    clean_value(row.get('potassium'), 'float'),
                    clean_value(row.get('magnesium'), 'float'),
                    clean_value(row.get('zinc'), 'float'),
                    clean_value(row.get('copper'), 'float'),
                    clean_value(row.get('manganese'), 'float'),
                    clean_value(row.get('selenium'), 'float'),
                    clean_value(row.get('beta_carotene'), 'float'),
                    clean_value(row.get('vitamin_a_iu'), 'float'),
                    clean_value(row.get('vitamin_a_rae'), 'float'),
                    clean_value(row.get('thiamin'), 'float'),
                    clean_value(row.get('vitamin_b6'), 'float'),
                    clean_value(row.get('vitamin_b12'), 'float'),
                    clean_value(row.get('vitamin_c'), 'float'),
                    clean_value(row.get('vitamin_d'), 'float'),
                    clean_value(row.get('vitamin_e'), 'float'),
                    clean_value(row.get('vitamin_k'), 'float'),
                    clean_value(row.get('folate_total'), 'float'),
                    clean_value(row.get('niacin'), 'float'),
                    clean_value(row.get('riboflavin'), 'float'),
                    clean_value(row.get('pantothenic_acid'), 'float'),
                    clean_value(row.get('choline'), 'float'),
                    clean_value(row.get('water'), 'float'),
                    clean_value(row.get('alcohol'), 'float'),
                    clean_value(row.get('caffeine'), 'float'),
                    clean_value(row.get('ash'), 'float'),
                    clean_value(row.get('category'))
                ))
                
                food_id = cursor.fetchone()[0]
                
                # Insert translations
                name_en = clean_value(row.get('name'))
                name_vi = clean_value(row.get('name_VN'))
                category_name = clean_value(row.get('category'))
                
                if name_en:
                    cursor.execute("""
                        INSERT INTO Food_Translations (food_id, language_id, name, category_name)
                        VALUES (?, ?, ?, ?)
                    """, (food_id, lang_en, name_en, category_name))
                
                if name_vi:
                    cursor.execute("""
                        INSERT INTO Food_Translations (food_id, language_id, name, category_name)
                        VALUES (?, ?, ?, ?)
                    """, (food_id, lang_vi, name_vi, category_name))
                
                # Insert amino acids
                cursor.execute("""
                    INSERT INTO Food_Amino_Acids (food_id, alanine, arginine, aspartic_acid, cystine,
                        glutamic_acid, glycine, histidine, hydroxyproline, isoleucine, leucine, lysine,
                        methionine, phenylalanine, proline, serine, threonine, tryptophan, tyrosine, valine)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    food_id,
                    clean_value(row.get('alanine'), 'float'),
                    clean_value(row.get('arginine'), 'float'),
                    clean_value(row.get('aspartic_acid'), 'float'),
                    clean_value(row.get('cystine'), 'float'),
                    clean_value(row.get('glutamic_acid'), 'float'),
                    clean_value(row.get('glycine'), 'float'),
                    clean_value(row.get('histidine'), 'float'),
                    clean_value(row.get('hydroxyproline'), 'float'),
                    clean_value(row.get('isoleucine'), 'float'),
                    clean_value(row.get('leucine'), 'float'),
                    clean_value(row.get('lysine'), 'float'),
                    clean_value(row.get('methionine'), 'float'),
                    clean_value(row.get('phenylalanine'), 'float'),
                    clean_value(row.get('proline'), 'float'),
                    clean_value(row.get('serine'), 'float'),
                    clean_value(row.get('threonine'), 'float'),
                    clean_value(row.get('tryptophan'), 'float'),
                    clean_value(row.get('tyrosine'), 'float'),
                    clean_value(row.get('valine'), 'float')
                ))
                
                # Insert fatty acids
                cursor.execute("""
                    INSERT INTO Food_Fatty_Acids (food_id, saturated_fatty_acids, monounsaturated_fatty_acids,
                        polyunsaturated_fatty_acids, fatty_acids_total_trans)
                    VALUES (?, ?, ?, ?, ?)
                """, (
                    food_id,
                    clean_value(row.get('fatty_acids_saturated'), 'float'),
                    clean_value(row.get('fatty_acids_monounsaturated'), 'float'),
                    clean_value(row.get('fatty_acids_polyunsaturated'), 'float'),
                    clean_value(row.get('fatty_acids_total_trans'), 'float')
                ))
                
                # Insert sugars
                cursor.execute("""
                    INSERT INTO Food_Sugars (food_id, fructose, galactose, glucose, lactose, maltose, sucrose)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (
                    food_id,
                    clean_value(row.get('fructose'), 'float'),
                    clean_value(row.get('galactose'), 'float'),
                    clean_value(row.get('glucose'), 'float'),
                    clean_value(row.get('lactose'), 'float'),
                    clean_value(row.get('maltose'), 'float'),
                    clean_value(row.get('sucrose'), 'float')
                ))
                
                # Insert carotenoids
                cursor.execute("""
                    INSERT INTO Food_Carotenoids (food_id, carotene_alpha, carotene_beta, cryptoxanthin_beta, lutein_zeaxanthin, lycopene)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (
                    food_id,
                    clean_value(row.get('carotene_alpha'), 'float'),
                    clean_value(row.get('carotene_beta'), 'float'),
                    clean_value(row.get('cryptoxanthin_beta'), 'float'),
                    clean_value(row.get('lutein_zeaxanthin'), 'float'),
                    clean_value(row.get('lycopene'), 'float')
                ))
                
                success += 1
                
                if success % 500 == 0:
                    print(f"   Progress: {success}...")
                    conn.commit()
                    
            except Exception as e:
                print(f"   Error row {idx}: {e}")
    
    conn.commit()
    
    # Verify
    cursor.execute("SELECT COUNT(*) FROM Foods WHERE source = 'nutrition_vn'")
    print(f"\n✅ Imported {success} foods from nutrition_VN.csv")
    print(f"📊 Total Foods (nutrition_vn): {cursor.fetchone()[0]}")
    
    cursor.close()
    conn.close()
    print("\n🔒 Done!")


if __name__ == "__main__":
    main()
