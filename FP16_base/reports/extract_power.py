import os
import re

# List of folders
folders = [
    "vectorless_fp16"
]

# Header for Excel
print("Folder,Leakage Power (W),Idle Power (W),Dynamic Power (W),Total Power (W)")

for folder in folders:
    file_path = os.path.join(folder, "power_flat.txt")

    try:
        with open(file_path, "r") as f:
            text = f.read()

        # Extract Subtotal row
        match = re.search(
            r"Subtotal\s+([\deE\+\-\.]+)\s+([\deE\+\-\.]+)\s+([\deE\+\-\.]+)\s+([\deE\+\-\.]+)",
            text
        )

        if match:
            leakage = float(match.group(1))
            internal = float(match.group(2))
            switching = float(match.group(3))
            total = float(match.group(4))

            idle = leakage + internal
            dynamic = internal + switching

            print(folder + "," + str(leakage) + "," + str(idle) + "," + str(dynamic) + "," + str(total))
        else:
            print(folder + "ERROR,ERROR,ERROR,ERROR")

    except FileNotFoundError:
        print(folder + "FILE NOT FOUND,FILE NOT FOUND,FILE NOT FOUND,FILE NOT FOUND")
