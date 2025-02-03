import os
import json
from bs4 import BeautifulSoup

# Folders
html_folder = "/Users/darinhall/IdeaProjects/CRS_Database/dpreview-data-specs/dpreview-data-specs/"  # Folder containing HTML files 
all_specs = "all_specs.json"


def extract_specs(filepath):
    """Extracts label-value pairs from an HTML file."""
    with open(filepath, 'r', encoding='utf-8') as file:
        soup = BeautifulSoup(file, 'lxml')

        specs = {}
        for row in soup.find("title"):
            item_title = row.get_text(strip=True) # Clean item title
            specs["Title: "] = item_title
        for row in soup.find_all("tr"):  # Iterate over table rows
            label_tag = row.find("th", class_="label")  # Find label
            value_tag = row.find("td", class_="value")  # Find value

            if label_tag and value_tag:
                label = label_tag.get_text(strip=True)  # Clean label
                value = value_tag.get_text(strip=True)  # Clean value
                specs[label] = value

        return specs

# Separate camera bodies and lenses
data = []

# Extract specs from each HTML file
for filename in os.listdir(html_folder):
    filepath = os.path.join(html_folder, filename)
    extracted_data = extract_specs(filepath)
    data.append(extracted_data)

# Save extracted data to JSON
with open(all_specs, 'w', encoding='utf-8') as cam_file:
    json.dump(data, cam_file, indent=4)

print(f"Extracted {len(data)} specs. Saved to JSON.")