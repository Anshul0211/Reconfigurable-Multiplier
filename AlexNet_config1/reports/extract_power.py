import os
import re

# List of folders
folders = [
    "5b_3e", "6b_4e", "7b_4e", "9b_4e",
    "10b_6e", "15b_4e", "16b_5e", "16b_8e"
]

# Header for Excel
print("Folder,Leakage Power (W),Idle Power (W),Dynamic Power (W),Total Power (W)")

for folder in folders:
    file_path = os.path.join(folder, "power_flat_" + folder + ".txt")

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
