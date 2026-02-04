"""
Update Exercise Translations - Thêm bản dịch VI cho các exercises đã có
"""
import pyodbc
import csv
import os

RESOURCES_DIR = 'd:/health_care/resources'

conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost;DATABASE=HeathCare;Trusted_Connection=yes')
cursor = conn.cursor()

# Get VI language id
cursor.execute("SELECT language_id FROM Languages WHERE code = 'vi'")
lang_vi = cursor.fetchone()[0]
print(f"VI language_id: {lang_vi}")

# Load and insert VI translations
trans_file = os.path.join(RESOURCES_DIR, 'Exercise_Translations.csv')
added = 0

with open(trans_file, 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    for row in reader:
        if row.get('language_code') == 'vi':
            slug = row.get('exercise_slug')
            name = row.get('name')
            
            # Get exercise_id
            cursor.execute('SELECT exercise_id FROM Exercises WHERE slug = ?', (slug,))
            result = cursor.fetchone()
            if not result:
                continue
            
            exercise_id = result[0]
            
            # Check if translation exists
            cursor.execute('SELECT 1 FROM Exercise_Translations WHERE exercise_id = ? AND language_id = ?', 
                          (exercise_id, lang_vi))
            if cursor.fetchone():
                continue
            
            # Insert
            cursor.execute('INSERT INTO Exercise_Translations (exercise_id, language_id, name) VALUES (?, ?, ?)',
                          (exercise_id, lang_vi, name))
            added += 1

conn.commit()
print(f'Added {added} Vietnamese translations')

cursor.execute('SELECT COUNT(*) FROM Exercise_Translations WHERE language_id = ?', (lang_vi,))
print(f'Total VI translations: {cursor.fetchone()[0]}')

conn.close()
print('Done!')
