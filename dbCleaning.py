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
            specs["Title"] = item_title
        #Add in for loop here for labeling for ease of use
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
mobileDevice = [] # Mobile devices, has "OS" in the specs
misc = [] # Anything that doesn't fit into the above categories
teleconverter = [] # Teleconverters are lenses that attach to other lenses to increase focal length

# Extract specs from each HTML file
for filename in os.listdir(html_folder):
    filepath = os.path.join(html_folder, filename)
    extracted_data = extract_specs(filepath)
    data.append(extracted_data)

# Sort extracted data into categories

for separator in data:
    if "Printer type" in separator:
        printer.append(separator)
    elif "OS" in separator:
        mobileDevice.append(separator)
    elif "Focal length" and "Body type" in separator and "Lens mount" not in separator:
        # the difference between fixed lens and lens is that fixed lens has body type in the specs
        fixed_lens.append(separator)
    elif "Viewfinder coverage" in separator or ("Timelapse Recording" and "GPS") in separator and separator not in fixed_lens: # accounting for DSLR and mirrorless, rangefinder, and SLR
        camera_body.append(separator)
    elif "Focal length" in separator and "Body type" not in separator:
        lens.append(separator)
    elif data["label"] == "Teleconverter" in separator:
        teleconverter.append(separator)
    else:
        misc.append(separator)
    '''
    elif separator not in camera_body and separator not in lens and separator not in printer and separator not in fixed_lens and separator not in mobileDevice:
        misc.append(separator)

    '''
# Save extracted data to JSON
with open(all_specs, 'w', encoding='utf-8') as cam_file:
    json.dump(data, cam_file, indent=4)

with open("camera_body.json", 'w', encoding='utf-8') as cam_file:
    json.dump(camera_body, cam_file, indent=4)

with open("lens.json", 'w', encoding='utf-8') as cam_file:
    json.dump(lens, cam_file, indent=4)

with open("printer.json", 'w', encoding='utf-8') as cam_file:
    json.dump(printer, cam_file, indent=4)

with open("fixed_lens.json", 'w', encoding='utf-8') as cam_file:
    json.dump(fixed_lens, cam_file, indent=4)

with open("mobileDevice.json", 'w', encoding='utf-8') as cam_file:
    json.dump(mobileDevice, cam_file, indent=4)

with open("misc.json", 'w', encoding='utf-8') as cam_file:
    json.dump(misc, cam_file, indent=4)

with open("teleconverter.json", 'w', encoding='utf-8') as cam_file:
    json.dump(teleconverter, cam_file, indent=4)

# Checks to make sure the data was extracted correctly



print(f"Extracted {len(data)} overall datapoints. These were separated into three main categories. "
      f"Extracted {len(camera_body)} camera bodies, {len(lens)} camera lenses, {len(printer)} printers, "
      f"{len(fixed_lens)} fixed-lens cameras, and {len(mobileDevice)} mobile devices were also extracted as of now. "
      f" {len(misc)} miscellaneously categorized data points. "
      " Saved to JSON. ")

#okay so the issue is that the sums are not adding up correctly; need to find out a way to (once a category is found) to not add it to the misc category; also
