"""
Import Recipes từ database và re-export với step-by-step instructions
Schema v2.1 - Recipe_Instructions với step_order
"""

import os
import csv
import re
import pyodbc

RESOURCES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "resources")
SERVER = 'localhost'
DATABASE = 'HeathCare'


def split_instructions_to_steps(text):
    """Split instruction text into individual steps"""
    if not text:
        return []
    
    # Common step patterns
    # 1. "Step 1:", "Step 2:", etc.
    # 2. "1.", "2.", etc.
    # 3. Newline separated
    
    # Try pattern: "Step X:" or "STEP X:"
    step_pattern = re.split(r'(?i)step\s*\d+[:\.]?\s*', text)
    if len(step_pattern) > 2:
        return [s.strip() for s in step_pattern if s.strip()]
    
    # Try pattern: numbered list "1." "2."
    numbered_pattern = re.split(r'\n\s*\d+[.)]\s*', text)
    if len(numbered_pattern) > 2:
        return [s.strip() for s in numbered_pattern if s.strip()]
    
    # Try newline split
    newline_split = text.split('\n')
    steps = []
    for line in newline_split:
        line = line.strip()
        # Remove leading numbers like "1." or "1)"
        line = re.sub(r'^\d+[.)]\s*', '', line)
        if line and len(line) > 10:  # Minimum step length
            steps.append(line)
    
    if len(steps) > 1:
        return steps
    
    # Last resort: split by periods for long sentences
    if len(text) > 200:
        sentences = text.split('. ')
        if len(sentences) > 2:
            return [s.strip() + '.' for s in sentences if s.strip() and len(s) > 20]
    
    # Return as single step
    return [text.strip()] if text.strip() else []


def main():
    print("=" * 60)
    print("EXPORT RECIPE INSTRUCTIONS AS STEPS")
    print("=" * 60)
    
    conn_str = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={SERVER};DATABASE={DATABASE};Trusted_Connection=yes'
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    print("Connected to SQL Server")
    
    # Get all recipes with their old instructions
    cursor.execute("""
        SELECT r.recipe_id, r.recipe_code, rt.name, rt.instructions
        FROM Recipes r
        JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id
        WHERE rt.language_id = 1
        ORDER BY r.recipe_id
    """)
    
    recipes = cursor.fetchall()
    print(f"Found {len(recipes)} recipes")
    
    # ========================================
    # Export to CSV with step-by-step format
    # ========================================
    steps_file = os.path.join(RESOURCES_DIR, "translate_recipe_steps.csv")
    
    total_steps = 0
    with open(steps_file, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerow(['recipe_code', 'name_en', 'step_order', 'instruction_en', 'instruction_vi'])
        
        for recipe_id, recipe_code, name, instructions in recipes:
            steps = split_instructions_to_steps(instructions)
            
            if not steps:
                # Write empty step for recipes without instructions
                writer.writerow([recipe_code, name, 1, '', ''])
                continue
            
            for step_order, step in enumerate(steps, 1):
                writer.writerow([recipe_code, name, step_order, step, ''])
                total_steps += 1
    
    print(f"\nExported: {steps_file}")
    print(f"Total steps: {total_steps}")
    
    # Show sample
    print("\n=== SAMPLE OUTPUT ===")
    cursor.execute("""
        SELECT TOP 1 r.recipe_code, rt.instructions
        FROM Recipes r
        JOIN Recipe_Translations rt ON r.recipe_id = rt.recipe_id
        WHERE rt.language_id = 1 AND rt.instructions IS NOT NULL
    """)
    sample = cursor.fetchone()
    if sample:
        print(f"Recipe: {sample[0]}")
        steps = split_instructions_to_steps(sample[1])
        print(f"Split into {len(steps)} steps:")
        for i, step in enumerate(steps[:3], 1):
            print(f"  Step {i}: {step[:80]}...")
    
    cursor.close()
    conn.close()
    
    print("\n" + "=" * 60)
    print("DONE!")
    print("=" * 60)
    print(f"\nFile: translate_recipe_steps.csv")
    print(f"Columns: recipe_code, name_en, step_order, instruction_en, instruction_vi")
    print(f"Fill in 'instruction_vi' column for each step")

if __name__ == "__main__":
    main()
