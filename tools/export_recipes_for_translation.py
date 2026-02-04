"""
Export Recipes to clean CSV files for translation
Creates optimized structure for Vietnamese translation
"""

import os
import csv
import pyodbc

RESOURCES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "resources")
SERVER = 'localhost'
DATABASE = 'HeathCare'


def main():
    print("=" * 60)
    print("EXPORT RECIPES FOR TRANSLATION")
    print("=" * 60)
    
    conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes'
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    print("Connected to SQL Server")
    
    # ========================================
    # 1. Export Recipe Names for translation
    # ========================================
    print("\n[1/3] Exporting Recipe Names...")
    
    names_file = os.path.join(RESOURCES_DIR, "translate_recipe_names.csv")
    cursor.execute("""
        SELECT r.recipe_code, r.category, r.area, rt.name as name_en
        FROM Recipes r
        JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id
        WHERE rt.language_id = 1
        ORDER BY r.recipe_id
    """)
    
    with open(names_file, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['recipe_code', 'category', 'area', 'name_en', 'name_vi'])
        for row in cursor.fetchall():
            writer.writerow([row[0], row[1], row[2], row[3], ''])  # name_vi empty for translation
    
    print(f"   Saved: {names_file}")
    
    # ========================================
    # 2. Export Recipe Instructions for translation
    # ========================================
    print("\n[2/3] Exporting Recipe Instructions...")
    
    instructions_file = os.path.join(RESOURCES_DIR, "translate_recipe_instructions.csv")
    cursor.execute("""
        SELECT r.recipe_code, rt.name as name_en, rt.instructions as instructions_en
        FROM Recipes r
        JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id
        WHERE rt.language_id = 1
        ORDER BY r.recipe_id
    """)
    
    with open(instructions_file, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerow(['recipe_code', 'name_en', 'instructions_en', 'instructions_vi'])
        for row in cursor.fetchall():
            # Clean instructions - replace newlines with | for easier editing
            instructions = row[2] or ''
            instructions_clean = instructions.replace('\r\n', ' | ').replace('\n', ' | ')
            writer.writerow([row[0], row[1], instructions_clean, ''])
    
    print(f"   Saved: {instructions_file}")
    
    # ========================================
    # 3. Export Ingredients for translation
    # ========================================
    print("\n[3/3] Exporting Recipe Ingredients...")
    
    ingredients_file = os.path.join(RESOURCES_DIR, "translate_recipe_ingredients.csv")
    cursor.execute("""
        SELECT DISTINCT ingredient_name
        FROM Recipe_Ingredients
        WHERE language_id = 1
        ORDER BY ingredient_name
    """)
    
    unique_ingredients = [row[0] for row in cursor.fetchall()]
    
    with open(ingredients_file, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['ingredient_en', 'ingredient_vi'])
        for ing in unique_ingredients:
            writer.writerow([ing, ''])
    
    print(f"   Saved: {ingredients_file}")
    print(f"   Unique ingredients: {len(unique_ingredients)}")
    
    # ========================================
    # Summary
    # ========================================
    cursor.execute("SELECT COUNT(*) FROM Recipes")
    recipe_count = cursor.fetchone()[0]
    
    print("\n" + "=" * 60)
    print("EXPORT COMPLETE!")
    print("=" * 60)
    print(f"\nTotal Recipes: {recipe_count}")
    print(f"\nFiles created:")
    print(f"  1. translate_recipe_names.csv")
    print(f"     - Columns: recipe_code, category, area, name_en, name_vi")
    print(f"     - Fill in 'name_vi' column")
    print(f"")
    print(f"  2. translate_recipe_instructions.csv")
    print(f"     - Columns: recipe_code, name_en, instructions_en, instructions_vi")
    print(f"     - Fill in 'instructions_vi' column")
    print(f"     - Instructions use ' | ' as step separator")
    print(f"")
    print(f"  3. translate_recipe_ingredients.csv")
    print(f"     - Columns: ingredient_en, ingredient_vi")
    print(f"     - Unique ingredients only ({len(unique_ingredients)} items)")
    print(f"     - Fill in 'ingredient_vi' column")
    
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
