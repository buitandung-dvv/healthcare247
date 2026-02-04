"""
Clone Recipes from TheMealDB API
Saves to CSV files for later import to SQL Server
No Google Translate - keep English for AI translation later
"""

import requests
import csv
import os
import time
from datetime import datetime

# Configuration
OUTPUT_DIR = "resources"
BASE_URL = "https://www.themealdb.com/api/json/v1/1"

# Create output directory
os.makedirs(OUTPUT_DIR, exist_ok=True)


def get_all_areas():
    """Get all cuisine areas"""
    url = f"{BASE_URL}/list.php?a=list"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            data = response.json()
            return [item['strArea'] for item in data.get('meals', [])]
    except Exception as e:
        print(f"Error getting areas: {e}")
    return []


def get_all_categories():
    """Get all meal categories"""
    url = f"{BASE_URL}/list.php?c=list"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            data = response.json()
            return [item['strCategory'] for item in data.get('meals', [])]
    except Exception as e:
        print(f"Error getting categories: {e}")
    return []


def get_meals_by_area(area):
    """Get meals by area/cuisine"""
    url = f"{BASE_URL}/filter.php?a={area}"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            return response.json().get('meals', []) or []
    except Exception as e:
        print(f"Error getting meals for area {area}: {e}")
    return []


def get_meals_by_category(category):
    """Get meals by category"""
    url = f"{BASE_URL}/filter.php?c={category}"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            return response.json().get('meals', []) or []
    except Exception as e:
        print(f"Error getting meals for category {category}: {e}")
    return []


def get_meals_by_first_letter(letter):
    """Get meals by first letter"""
    url = f"{BASE_URL}/search.php?f={letter}"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            return response.json().get('meals', []) or []
    except Exception as e:
        print(f"Error getting meals for letter {letter}: {e}")
    return []


def get_meal_details(meal_id):
    """Get full meal details by ID"""
    url = f"{BASE_URL}/lookup.php?i={meal_id}"
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            meals = response.json().get('meals', [])
            return meals[0] if meals else None
    except Exception as e:
        print(f"Error getting meal {meal_id}: {e}")
    return None


def parse_ingredients(meal):
    """Parse ingredients from meal data"""
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


def main():
    print("=" * 70)
    print("🍳 CLONE RECIPES FROM TheMealDB API")
    print("=" * 70)
    print(f"📅 Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("")

    # Get all areas and categories
    print("📋 Fetching areas and categories...")
    areas = get_all_areas()
    categories = get_all_categories()
    print(f"   Found {len(areas)} areas: {', '.join(areas)}")
    print(f"   Found {len(categories)} categories: {', '.join(categories)}")
    print("")

    # Collect all unique meal IDs
    print("🔍 Collecting meal IDs...")
    all_meal_ids = set()

    # From areas
    for area in areas:
        meals = get_meals_by_area(area)
        for meal in meals:
            all_meal_ids.add(meal['idMeal'])
        print(f"   {area}: {len(meals)} meals (Total: {len(all_meal_ids)})")
        time.sleep(0.2)

    # From categories
    for category in categories:
        meals = get_meals_by_category(category)
        for meal in meals:
            all_meal_ids.add(meal['idMeal'])
        print(f"   {category}: {len(meals)} meals (Total: {len(all_meal_ids)})")
        time.sleep(0.2)

    # From A-Z search
    print("\n🔤 Searching A-Z...")
    for letter in 'abcdefghijklmnopqrstuvwxyz':
        meals = get_meals_by_first_letter(letter)
        if meals:
            for meal in meals:
                all_meal_ids.add(meal['idMeal'])
            print(f"   Letter {letter.upper()}: {len(meals)} meals")
        time.sleep(0.2)

    print(f"\n📊 Total unique meals found: {len(all_meal_ids)}")
    print("")

    # Prepare CSV files
    recipes_file = os.path.join(OUTPUT_DIR, "recipes.csv")
    translations_file = os.path.join(OUTPUT_DIR, "recipe_translations.csv")
    ingredients_file = os.path.join(OUTPUT_DIR, "recipe_ingredients.csv")

    # CSV headers
    recipes_headers = [
        'recipe_code', 'themealdb_id', 'category', 'area',
        'image_url', 'youtube_url', 'source_url', 'tags'
    ]
    translations_headers = [
        'recipe_code', 'language_code', 'name', 'instructions'
    ]
    ingredients_headers = [
        'recipe_code', 'language_code', 'ingredient_name', 'measure', 'display_order'
    ]

    # Open CSV files
    recipes_csv = open(recipes_file, 'w', newline='', encoding='utf-8')
    translations_csv = open(translations_file, 'w', newline='', encoding='utf-8')
    ingredients_csv = open(ingredients_file, 'w', newline='', encoding='utf-8')

    recipes_writer = csv.DictWriter(recipes_csv, fieldnames=recipes_headers)
    translations_writer = csv.DictWriter(translations_csv, fieldnames=translations_headers)
    ingredients_writer = csv.DictWriter(ingredients_csv, fieldnames=ingredients_headers)

    recipes_writer.writeheader()
    translations_writer.writeheader()
    ingredients_writer.writeheader()

    # Fetch meal details
    print("📥 Fetching meal details...")
    success_count = 0
    error_count = 0

    for idx, meal_id in enumerate(all_meal_ids, 1):
        try:
            meal = get_meal_details(meal_id)
            if not meal:
                error_count += 1
                continue

            meal_name = meal.get('strMeal', '')
            recipe_code = meal_name.lower().replace(' ', '-').replace("'", "")
            recipe_code = ''.join(c for c in recipe_code if c.isalnum() or c == '-')

            # Write recipe
            recipes_writer.writerow({
                'recipe_code': recipe_code,
                'themealdb_id': meal.get('idMeal', ''),
                'category': meal.get('strCategory', ''),
                'area': meal.get('strArea', ''),
                'image_url': meal.get('strMealThumb', ''),
                'youtube_url': meal.get('strYoutube', ''),
                'source_url': meal.get('strSource', ''),
                'tags': meal.get('strTags', '')
            })

            # Write English translation
            translations_writer.writerow({
                'recipe_code': recipe_code,
                'language_code': 'en',
                'name': meal_name,
                'instructions': meal.get('strInstructions', '')
            })

            # Write ingredients (English only)
            ingredients = parse_ingredients(meal)
            for ing in ingredients:
                ingredients_writer.writerow({
                    'recipe_code': recipe_code,
                    'language_code': 'en',
                    'ingredient_name': ing['ingredient'],
                    'measure': ing['measure'],
                    'display_order': ing['order']
                })

            success_count += 1

            if idx % 50 == 0:
                print(f"   Progress: {idx}/{len(all_meal_ids)} ({success_count} success, {error_count} errors)")
                # Flush files periodically
                recipes_csv.flush()
                translations_csv.flush()
                ingredients_csv.flush()

            time.sleep(0.1)  # Rate limiting

        except Exception as e:
            error_count += 1
            print(f"   Error processing meal {meal_id}: {e}")

    # Close files
    recipes_csv.close()
    translations_csv.close()
    ingredients_csv.close()

    # Summary
    print("")
    print("=" * 70)
    print("✅ CLONE COMPLETE!")
    print("=" * 70)
    print(f"📊 Total meals processed: {success_count}")
    print(f"❌ Errors: {error_count}")
    print("")
    print("📁 Output files:")
    print(f"   - {recipes_file}")
    print(f"   - {translations_file}")
    print(f"   - {ingredients_file}")
    print("")
    print("💡 Next steps:")
    print("   1. Translate recipe names and instructions to Vietnamese using AI")
    print("   2. Add Vietnamese translations to recipe_translations.csv")
    print("   3. Add Vietnamese ingredients to recipe_ingredients.csv")
    print("   4. Import to SQL Server using HealthCare.sql")
    print("=" * 70)
    print(f"📅 Finished: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")


if __name__ == "__main__":
    main()
