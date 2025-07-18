import dbCleaning2
import os
import json


def count_items_in_json_files():
        for filename in os.listdir(dbCleaning2.HTML_FOLDER):
            if filename.endswith('.json'):
                filepath = os.path.join(dbCleaning2.HTML_FOLDER, filename)
                with open(filepath, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    print(f"{filename}: {len(data)} items")
