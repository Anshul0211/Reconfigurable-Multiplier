import os
import pandas as pd

# folders containing Results/summary_stats.csv
configs = ["5b3e","6b4e","7b4e","8b4e","9b4e","10b6e","15b4e"]

all_data = []

for cfg in configs:

    file_path = os.path.join(cfg, "Results", "summary_stats.csv")

    if os.path.exists(file_path):

        df = pd.read_csv(file_path)

        # add configuration column
        df["Configuration"] = cfg

        all_data.append(df)

    else:
        print("Missing file:", file_path)

# combine all dataframes
combined_df = pd.concat(all_data, ignore_index=True)

# save combined csv
combined_df.to_csv("combined_summary.csv", index=False)

print("Created file: combined_summary.csv")