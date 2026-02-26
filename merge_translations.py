import json
import os

json_path = r"d:\TheekaOnline\assets\languages\translations.json"
new_json_path = r"d:\TheekaOnline\missing_translations.json"

with open(json_path, 'r', encoding='utf-8') as f:
    current_data = json.load(f)

with open(new_json_path, 'r', encoding='utf-8') as f:
    new_data = json.load(f)

# Merge data
for key, value in new_data.items():
    if key not in current_data:
        current_data[key] = value

# Save back with proper formatting and UTF-8
with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(current_data, f, ensure_ascii=False, indent=2)

print(f"Successfully merged. Total keys: {len(current_data)}")
