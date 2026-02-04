"""
Import Recipes - Clone từ TheMealDB API + thêm bản dịch tiếng Việt từ CSV
"""

import os
import csv
import requests
import time
import pyodbc

RESOURCES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "resources")
SERVER = 'localhost'
DATABASE = 'HeathCare'
BASE_URL = "https://www.themealdb.com/api/json/v1/1"


def clean_value(value, value_type='string'):
    if value is None or value == '' or value == 'NULL':
        return None
    if value_type == 'int':
        try:
            return int(float(str(value).replace(',', '')))
        except ValueError:
            return None
    return str(value).strip()


def get_all_meal_ids():
    """Get all meal IDs from API"""
    all_ids = set()
    
    # From A-Z search
    for letter in 'abcdefghijklmnopqrstuvwxyz':
        try:
            response = requests.get(f"{BASE_URL}/search.php?f={letter}", timeout=10)
            if response.status_code == 200:
                meals = response.json().get('meals', []) or []
                for meal in meals:
                    all_ids.add(meal['idMeal'])
            time.sleep(0.1)
        except:
            pass
    
    return all_ids


def get_meal_details(meal_id):
    """Get full meal details by ID"""
    try:
        response = requests.get(f"{BASE_URL}/lookup.php?i={meal_id}", timeout=10)
        if response.status_code == 200:
            meals = response.json().get('meals', [])
            return meals[0] if meals else None
    except:
        pass
    return None


def parse_ingredients(meal):
    """Parse ingredients from meal data"""
    ingredients = []
    for i in range(1, 21):
        ingredient = (meal.get(f'strIngredient{i}') or '').strip()
        measure = (meal.get(f'strMeasure{i}') or '').strip()
        if ingredient and ingredient.lower() not in ['', 'null', 'none']:
            ingredients.append({'ingredient': ingredient, 'measure': measure, 'order': i})
    return ingredients


def main():
    print("=" * 60)
    print("IMPORT RECIPES (Clone from API + Vietnamese translations)")
    print("=" * 60)
    
    conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes'
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    print("Connected to SQL Server")
    
    # Get language IDs
    cursor.execute("SELECT language_id FROM Languages WHERE code = 'en'")
    lang_en = cursor.fetchone()[0]
    cursor.execute("SELECT language_id FROM Languages WHERE code = 'vi'")
    lang_vi = cursor.fetchone()[0]
    
    # ========================================
    # Step 1: Clone from TheMealDB API
    # ========================================
    print("\n[1/4] Cloning recipes from TheMealDB API...")
    meal_ids = get_all_meal_ids()
    print(f"   Found {len(meal_ids)} meals")
    
    recipes_cloned = 0
    for idx, meal_id in enumerate(meal_ids, 1):
        meal = get_meal_details(meal_id)
        if not meal:
            continue
        
        meal_name = meal.get('strMeal', '')
        recipe_code = meal_name.lower().replace(' ', '-').replace("'", "")
        recipe_code = ''.join(c for c in recipe_code if c.isalnum() or c == '-')
        
        # Check if exists
        cursor.execute("SELECT recipe_id FROM Recipes WHERE recipe_code = ?", (recipe_code,))
        if cursor.fetchone():
            continue
        
        # Insert recipe
        cursor.execute("""
            INSERT INTO Recipes (recipe_code, themealdb_id, category, area, image_url, 
                                 thumbnail_url, youtube_url, source_url, tags)
            OUTPUT INSERTED.recipe_id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            recipe_code,
            meal.get('idMeal'),
            meal.get('strCategory'),
            meal.get('strArea'),
            meal.get('strMealThumb'),
            meal.get('strMealThumb') + '/preview' if meal.get('strMealThumb') else None,
            meal.get('strYoutube'),
            meal.get('strSource'),
            meal.get('strTags')
        ))
        recipe_id = cursor.fetchone()[0]
        
        # Insert English translation
        cursor.execute("""
            INSERT INTO Recipe_Translations (recipe_id, language_id, name, overview)
            VALUES (?, ?, ?, ?)
        """, (recipe_id, lang_en, meal_name, meal.get('strInstructions')))
        
        # Insert English ingredients
        for ing in parse_ingredients(meal):
            cursor.execute("""
                INSERT INTO Recipe_Ingredients (recipe_id, language_id, display_order, ingredient_name, measure)
                VALUES (?, ?, ?, ?, ?)
            """, (recipe_id, lang_en, ing['order'], ing['ingredient'], ing['measure']))
        
        recipes_cloned += 1
        if idx % 50 == 0:
            print(f"   Progress: {idx}/{len(meal_ids)}")
            conn.commit()
        
        time.sleep(0.05)
    
    conn.commit()
    print(f"   Cloned {recipes_cloned} recipes from API")
    
    # ========================================
    # Step 2: Add Vietnamese translations from CSV
    # ========================================
    names_file = os.path.join(RESOURCES_DIR, "translate_recipe_names.csv")
    
    if os.path.exists(names_file):
        print("\n[2/4] Adding Vietnamese names...")
        count = 0
        
        with open(names_file, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                recipe_code = clean_value(row.get('recipe_code'))
                name_vi = clean_value(row.get('name_vi'))
                if not recipe_code or not name_vi:
                    continue
                
                cursor.execute("SELECT recipe_id FROM Recipes WHERE recipe_code = ?", (recipe_code,))
                result = cursor.fetchone()
                if not result:
                    continue
                
                recipe_id = result[0]
                cursor.execute("""
                    IF NOT EXISTS (SELECT 1 FROM Recipe_Translations WHERE recipe_id = ? AND language_id = ?)
                    INSERT INTO Recipe_Translations (recipe_id, language_id, name)
                    VALUES (?, ?, ?)
                """, (recipe_id, lang_vi, recipe_id, lang_vi, name_vi))
                count += 1
        
        conn.commit()
        print(f"   Added {count} Vietnamese names")
    
    # ========================================
    # Step 3: Add Vietnamese overviews
    # ========================================
    overview_file = os.path.join(RESOURCES_DIR, "translate_recipe_instructions.csv")
    
    if os.path.exists(overview_file):
        print("\n[3/4] Adding Vietnamese overviews...")
        count = 0
        
        with open(overview_file, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                recipe_code = clean_value(row.get('recipe_code'))
                overview_vi = clean_value(row.get('instructions_vn'))
                if not recipe_code or not overview_vi:
                    continue
                
                cursor.execute("SELECT recipe_id FROM Recipes WHERE recipe_code = ?", (recipe_code,))
                result = cursor.fetchone()
                if not result:
                    continue
                
                recipe_id = result[0]
                cursor.execute("""
                    UPDATE Recipe_Translations SET overview = ?
                    WHERE recipe_id = ? AND language_id = ?
                """, (overview_vi, recipe_id, lang_vi))
                count += 1
        
        conn.commit()
        print(f"   Added {count} Vietnamese overviews")
    
    # ========================================
    # Step 4: Add Vietnamese steps
    # ========================================
    steps_file = os.path.join(RESOURCES_DIR, "translate_recipe_steps.csv")
    
    if os.path.exists(steps_file):
        print("\n[4/4] Adding Vietnamese steps...")
        count = 0
        
        with open(steps_file, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                recipe_code = clean_value(row.get('recipe_code'))
                step_order = clean_value(row.get('step_order'), 'int') or 1
                instruction_en = clean_value(row.get('instruction_en'))
                instruction_vi = clean_value(row.get('instruction_vi'))
                
                if not recipe_code:
                    continue
                
                cursor.execute("SELECT recipe_id FROM Recipes WHERE recipe_code = ?", (recipe_code,))
                result = cursor.fetchone()
                if not result:
                    continue
                
                recipe_id = result[0]
                
                # Insert English step
                if instruction_en:
                    try:
                        cursor.execute("""
                            INSERT INTO Recipe_Instructions (recipe_id, language_id, step_order, instruction)
                            VALUES (?, ?, ?, ?)
                        """, (recipe_id, lang_en, step_order, instruction_en))
                    except:
                        pass
                
                # Insert Vietnamese step
                if instruction_vi:
                    try:
                        cursor.execute("""
                            INSERT INTO Recipe_Instructions (recipe_id, language_id, step_order, instruction)
                            VALUES (?, ?, ?, ?)
                        """, (recipe_id, lang_vi, step_order, instruction_vi))
                        count += 1
                    except:
                        pass
        
        conn.commit()
        print(f"   Added {count} Vietnamese steps")
    
    # ========================================
    # Summary
    # ========================================
    print("\n" + "=" * 60)
    print("IMPORT COMPLETE!")
    print("=" * 60)
    
    cursor.execute("SELECT COUNT(*) FROM Recipes")
    print(f"Recipes: {cursor.fetchone()[0]}")
    
    cursor.execute("SELECT COUNT(*) FROM Recipe_Translations WHERE language_id = 1")
    print(f"Translations (EN): {cursor.fetchone()[0]}")
    
    cursor.execute("SELECT COUNT(*) FROM Recipe_Translations WHERE language_id = 2")
    print(f"Translations (VI): {cursor.fetchone()[0]}")
    
    cursor.execute("SELECT COUNT(*) FROM Recipe_Instructions WHERE language_id = 2")
    print(f"Instructions (VI): {cursor.fetchone()[0]}")
    
    cursor.execute("SELECT COUNT(*) FROM Recipe_Ingredients")
    print(f"Ingredients: {cursor.fetchone()[0]}")
    
    # Show sample with image
    print("\nSample Recipe:")
    cursor.execute("""
        SELECT TOP 1 r.recipe_code, r.image_url, rt.name
        FROM Recipes r
        JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id
        WHERE rt.language_id = 2 AND r.image_url IS NOT NULL
    """)
    row = cursor.fetchone()
    if row:
        print(f"  {row[0]}: {row[2]}")
        print(f"  Image: {row[1]}")
    
    cursor.close()
    conn.close()
    print("\nDone!")


if __name__ == "__main__":
    main()
