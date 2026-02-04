"""Fix Daily_Food_Translations - thêm translations thiếu"""
import pyodbc
import csv

conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost;DATABASE=HeathCare;Trusted_Connection=yes')
cursor = conn.cursor()

cursor.execute("SELECT language_id FROM Languages WHERE code = 'en'")
lang_en = cursor.fetchone()[0]
cursor.execute("SELECT language_id FROM Languages WHERE code = 'vi'")
lang_vi = cursor.fetchone()[0]

csv_file = 'd:/health_care/resources/daily_food_nutrition_dataset_VN.csv'
added = 0

with open(csv_file, 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    for idx, row in enumerate(reader, 1):
        code = f'daily_{idx}'
        
        cursor.execute('SELECT daily_food_id FROM Daily_Foods WHERE code = ?', (code,))
        result = cursor.fetchone()
        if not result:
            continue
        
        daily_food_id = result[0]
        
        # EN
        cursor.execute('SELECT 1 FROM Daily_Food_Translations WHERE daily_food_id = ? AND language_id = ?', (daily_food_id, lang_en))
        if not cursor.fetchone():
            cursor.execute('INSERT INTO Daily_Food_Translations (daily_food_id, language_id, name, category_name) VALUES (?, ?, ?, ?)',
                          (daily_food_id, lang_en, row.get('Food_Item'), row.get('Category')))
            added += 1
        
        # VI
        cursor.execute('SELECT 1 FROM Daily_Food_Translations WHERE daily_food_id = ? AND language_id = ?', (daily_food_id, lang_vi))
        if not cursor.fetchone():
            cursor.execute('INSERT INTO Daily_Food_Translations (daily_food_id, language_id, name, category_name) VALUES (?, ?, ?, ?)',
                          (daily_food_id, lang_vi, row.get('Food_Item_VN'), row.get('Category_VN')))
            added += 1

conn.commit()
print(f'Added {added} translations')

cursor.execute('SELECT COUNT(*) FROM Daily_Food_Translations')
print(f'Total Daily_Food_Translations: {cursor.fetchone()[0]}')
conn.close()
