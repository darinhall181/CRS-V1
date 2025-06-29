import os
import json
from bs4 import BeautifulSoup

# Folders
HTML_FOLDER = "/Users/darinhall/IdeaProjects/CRS_Database/dpreview-data-specs/dpreview-data-specs/"
ALL_SPECS_FILE = "all_specs.json"

'''
Category explanation:

camera_body: cameras with interchangable lenses
lens: camera lenses that are standalone and can be attached to a camera body
ptinter: just printers lol, has "Printer type" in the specs
fixed_lens: fixed-lens cameras are cameras with a non-interchangeable lenses, when comparing to camera_body they have focal length and aperture in the specs
mobile_device: 
'''

CATEGORY_FILES = {
    "camera_body": "camera_body.json",
    "lens": "lens.json",
    "printer": "printer.json",
    "fixed_lens": "fixed_lens.json",
    "mobile_device": "mobile_device.json",
    "teleconverter": "teleconverter.json",
    "misc": "misc.json"
}

def extract_specs(filepath):
    """Extract label-value pairs from an HTML file."""
    with open(filepath, 'r', encoding='utf-8') as file:
        soup = BeautifulSoup(file, 'lxml')

    specs = {}
    title_tag = soup.find("title")
    if title_tag:
        item_title = title_tag.get_text(strip=True).rstrip(" Specs: Digital Photography Review")
        specs["Title"] = item_title

    for row in soup.find_all("tr"):
        label_tag = row.find("th", class_="label")
        value_tag = row.find("td", class_="value")

        if label_tag and value_tag:
            label = label_tag.get_text(strip=True)
            value = value_tag.get_text(strip=True)
            specs[label] = value

    return specs


def categorize_item(item):
    """Categorize a single item based on its specs."""
    lens_type = item.get("Lens type", "").strip().lower()

    if "Printer type" in item:
        return "printer"
    elif "OS" in item:
        return "mobile_device"
    elif "Focal length" and "Body type" in item and "Lens mount" not in item:
        return "fixed_lens"
    elif "Viewfinder coverage" in item or ("Timelapse Recording" in item and "GPS" in item):
        return "camera_body"
    elif "Focal length" in item and "Body type" not in item:
        return "lens"
    elif lens_type == "teleconverter":
        return "teleconverter"
    else:
        return "misc"
    
def reclassify_misc(categories):
    still_misc = []
    for item in categories["misc"]:
        if ("Exposure compensation" in item):
            categories["camera_body"].append(item)
        else:
            still_misc.append(item)

    categories["misc"] = still_misc


def save_json(data, filename):
    with open(filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)

def main():
    data = [] # List of extracted specs (no separation)
    categories = {key: [] for key in CATEGORY_FILES}

    for filename in os.listdir(HTML_FOLDER):
        filepath = os.path.join(HTML_FOLDER, filename)
        extracted_data = extract_specs(filepath)
        data.append(extracted_data)

        category = categorize_item(extracted_data)
        categories[category].append(extracted_data)
    
    reclassify_misc(categories)

    save_json(data, ALL_SPECS_FILE)

    for cat, items in categories.items():
        save_json(items, CATEGORY_FILES[cat])

    print(f"Extracted {len(data)} total data points.")
    for cat, items in categories.items():
        print(f"{cat}: {len(items)}")

if __name__ == "__main__":
    main()
