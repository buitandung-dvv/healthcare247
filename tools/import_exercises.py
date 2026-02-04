"""
Import Exercises từ exercises.json + CSV translations
Schema Optimized v2.0 - composite primary keys
"""

import os
import csv
import json
import pyodbc
from datetime import datetime

TOOLS_DIR = os.path.dirname(__file__)
RESOURCES_DIR = os.path.join(os.path.dirname(TOOLS_DIR), "resources")
SERVER = 'localhost'
DATABASE = 'HeathCare'


def clean_value(value, value_type='string'):
    if value is None or value == '' or value == 'NULL':
        return None
    if value_type == 'int':
        try:
            return int(float(str(value).replace(',', '')))
        except ValueError:
            return None
    return str(value).strip()


def load_translations():
    """Load Vietnamese translations from CSV files"""
    translations = {}
    instructions_vi = {}
    
    # Load name translations
    trans_file = os.path.join(RESOURCES_DIR, "Exercise_Translations.csv")
    if os.path.exists(trans_file):
        with open(trans_file, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row.get('language_code') == 'vi':
                    translations[row.get('exercise_slug')] = row.get('name')
    
    # Load instruction translations
    instr_file = os.path.join(RESOURCES_DIR, "ExerciseInstructions.csv")
    if os.path.exists(instr_file):
        with open(instr_file, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row.get('language_code') == 'vi':
                    slug = row.get('exercise_slug')
                    if slug not in instructions_vi:
                        instructions_vi[slug] = {}
                    step = clean_value(row.get('step_order'), 'int') or 1
                    instructions_vi[slug][step] = row.get('instruction')
    
    return translations, instructions_vi


def main():
    print("=" * 60)
    print("📥 IMPORT EXERCISES (from JSON + CSV translations)")
    print("=" * 60)
    
    conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes'
    json_file = os.path.join(TOOLS_DIR, "exercises.json")
    
    if not os.path.exists(json_file):
        print(f"❌ File không tồn tại: {json_file}")
        return
    
    # Load JSON data
    print("📋 Loading exercises.json...")
    with open(json_file, 'r', encoding='utf-8') as f:
        exercises = json.load(f)
    print(f"   Found {len(exercises)} exercises")
    
    # Load Vietnamese translations
    print("📋 Loading Vietnamese translations from CSV...")
    name_translations, instructions_vi = load_translations()
    print(f"   Found {len(name_translations)} name translations")
    print(f"   Found {len(instructions_vi)} instruction translations")
    
    # Connect to database
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    print("✅ Connected to SQL Server")
    
    # Get language IDs
    cursor.execute("SELECT language_id FROM Languages WHERE code = 'en'")
    lang_en = cursor.fetchone()[0]
    cursor.execute("SELECT language_id FROM Languages WHERE code = 'vi'")
    lang_vi = cursor.fetchone()[0]
    
    success = 0
    
    for ex in exercises:
        try:
            slug = ex.get('id')
            if not slug:
                continue
            
            # Check if exists
            cursor.execute("SELECT exercise_id FROM Exercises WHERE slug = ?", (slug,))
            if cursor.fetchone():
                continue
            
            # Insert Exercise
            cursor.execute("""
                INSERT INTO Exercises (slug, force, level, mechanic, equipment, category)
                OUTPUT INSERTED.exercise_id
                VALUES (?, ?, ?, ?, ?, ?)
            """, (
                slug,
                ex.get('force'),
                ex.get('level') or 'beginner',
                ex.get('mechanic'),
                ex.get('equipment'),
                ex.get('category') or 'strength'
            ))
            
            exercise_id = cursor.fetchone()[0]
            
            # Insert English translation
            name_en = ex.get('name')
            if name_en:
                cursor.execute("""
                    INSERT INTO Exercise_Translations (exercise_id, language_id, name)
                    VALUES (?, ?, ?)
                """, (exercise_id, lang_en, name_en))
            
            # Insert Vietnamese translation
            name_vi = name_translations.get(slug)
            if name_vi:
                cursor.execute("""
                    INSERT INTO Exercise_Translations (exercise_id, language_id, name)
                    VALUES (?, ?, ?)
                """, (exercise_id, lang_vi, name_vi))
            
            # Insert Images (with display_order)
            images = ex.get('images', [])
            for order, img in enumerate(images):
                try:
                    cursor.execute("""
                        INSERT INTO ExerciseImages (exercise_id, image_url, display_order)
                        VALUES (?, ?, ?)
                    """, (exercise_id, img, order))
                except:
                    pass
            
            # Insert Primary Muscles (composite PK)
            for muscle in ex.get('primaryMuscles', []):
                try:
                    cursor.execute("""
                        INSERT INTO ExercisePrimaryMuscles (exercise_id, muscle)
                        VALUES (?, ?)
                    """, (exercise_id, muscle))
                except:
                    pass
            
            # Insert Secondary Muscles (composite PK)
            for muscle in ex.get('secondaryMuscles', []):
                try:
                    cursor.execute("""
                        INSERT INTO ExerciseSecondaryMuscles (exercise_id, muscle)
                        VALUES (?, ?)
                    """, (exercise_id, muscle))
                except:
                    pass
            
            # Insert Instructions - English
            instructions_en = ex.get('instructions', [])
            for step, instr in enumerate(instructions_en, 1):
                cursor.execute("""
                    INSERT INTO ExerciseInstructions (exercise_id, language_id, step_order, instruction)
                    VALUES (?, ?, ?, ?)
                """, (exercise_id, lang_en, step, instr))
            
            # Insert Instructions - Vietnamese
            if slug in instructions_vi:
                for step, instr in instructions_vi[slug].items():
                    cursor.execute("""
                        INSERT INTO ExerciseInstructions (exercise_id, language_id, step_order, instruction)
                        VALUES (?, ?, ?, ?)
                    """, (exercise_id, lang_vi, step, instr))
            
            success += 1
            
            if success % 100 == 0:
                print(f"   Progress: {success}...")
                conn.commit()
                
        except Exception as e:
            print(f"   Error {slug}: {e}")
    
    conn.commit()
    
    # Summary
    print("\n" + "=" * 60)
    print("✅ IMPORT COMPLETE!")
    print("=" * 60)
    
    for table in ['Exercises', 'Exercise_Translations', 'ExerciseImages', 
                  'ExerciseInstructions', 'ExercisePrimaryMuscles', 'ExerciseSecondaryMuscles']:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        print(f"📊 {table}: {cursor.fetchone()[0]}")
    
    # Show level distribution
    cursor.execute("SELECT level, COUNT(*) FROM Exercises GROUP BY level")
    print("\n📊 By Level:")
    for row in cursor.fetchall():
        print(f"   - {row[0]}: {row[1]}")
    
    cursor.close()
    conn.close()
    print("\n🔒 Done!")


if __name__ == "__main__":
    main()
