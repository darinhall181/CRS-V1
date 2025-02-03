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
            item_title = row.get_text(strip=True).rstrip(" Specs: Digital Photography Review") # Clean item title
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
data = [] # List of extracted specs (no separation)
camera_body = [] # Cameras with interchangeable lenses
lens = [] # Camera lenses that can be attached to a camera body
printer = [] # Just printers lol, has "Printer type" in the specs
fixed_lens = [] # Fixed-lens cameras are cameras with a non-interchangeable lenses, when comparing to camera_body they have focal length and aperture in the specs

# Extract specs from each HTML file
for filename in os.listdir(html_folder):
    filepath = os.path.join(html_folder, filename)
    extracted_data = extract_specs(filepath)
    data.append(extracted_data)

# Save extracted data to JSON
with open(all_specs, 'w', encoding='utf-8') as cam_file:
    json.dump(data, cam_file, indent=4)

print(f"Extracted {len(data)} specs. Saved to JSON.")