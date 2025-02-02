import os
import json
from bs4 import BeautifulSoup

# Folders
html_folder = "/Users/darinhall/IdeaProjects/CRS_Database/dpreview-data-specs/dpreview-data-specs/"  # Folder containing HTML files 
output_camera_json = "camera_specs.json"
output_lens_json = "lens_specs.json"

def extract_specs(filepath):
    """Extracts label-value pairs from an HTML file."""
    with open(filepath, 'r', encoding='utf-8') as file:
        soup = BeautifulSoup(file, 'lxml')

        specs = {}
        for row in soup.find_all("tr"):  # Iterate over table rows
            label_tag = row.find("th", class_="label")  # Find label
            value_tag = row.find("td", class_="value")  # Find value

            if label_tag and value_tag:
                label = label_tag.get_text(strip=True)  # Clean label
                value = value_tag.get_text(strip=True)  # Clean value
                specs[label] = value

        return specs

# Separate camera bodies and lenses
data_camera = []
data_lens = []

for filename in os.listdir(html_folder):
    filepath = os.path.join(html_folder, filename)

    if os.path.isfile(filepath):
        extracted_data = extract_specs(filepath)
        
        if "lens" in filename.lower():
            data_lens.append(extracted_data)
        else:
            data_camera.append(extracted_data)

# Save extracted data to JSON
with open(output_camera_json, 'w', encoding='utf-8') as cam_file:
    json.dump(data_camera, cam_file, indent=4)

with open(output_lens_json, 'w', encoding='utf-8') as lens_file:
    json.dump(data_lens, lens_file, indent=4)

print(f"Extracted {len(data_camera)} camera specs and {len(data_lens)} lens specs. Saved to JSON.")

print("Files in directory:", os.listdir(html_folder))  