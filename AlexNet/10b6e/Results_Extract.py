import os
import pandas as pd

root_directory = 'Results/'

csv_filename = 'summary_stats.csv'
csv_filepath = os.path.join(root_directory, csv_filename)

rows = []

for root, dirs, files in os.walk(root_directory):
    for f in files:
        if f == 'timeloop-mapper.stats.txt':

            filepath = os.path.join(root, f)

            with open(filepath, 'r') as file:

                lines = file.readlines()

                start_index = lines.index('Summary Stats\n')
                end_index = start_index + 25

                summary_lines = lines[start_index:end_index]

                utilization_line = summary_lines[3]
                cycles_line = summary_lines[4]
                energy_line = summary_lines[5]
                edp_line = summary_lines[6]
                computes_line = summary_lines[9]
                pJ_MACC_line = summary_lines[11]
                pJ_PEWeightRegs_line = summary_lines[12]
                pJ_InputBuffer_line = summary_lines[13]
                pJ_Accumulator_line = summary_lines[14]
                pJ_GlobalBuffer_line = summary_lines[15]
                pJ_DRAM_line = summary_lines[16]
                pJ_line = summary_lines[22]

                utilization = float(utilization_line.split()[-1])
                cycles = int(cycles_line.split()[-1])
                energy = float(energy_line.split()[-2])
                edp = float(edp_line.split()[-1])
                computes = int(computes_line.split()[-1])

                pJ_MACC = float(pJ_MACC_line.split()[-1])
                pJ_PEWeightRegs = float(pJ_PEWeightRegs_line.split()[-1])
                pJ_PEAccuBuffer = float(pJ_Accumulator_line.split()[-1])
                pJ_PEInputBuffer = float(pJ_InputBuffer_line.split()[-1])
                pJ_GlobalBuffer = float(pJ_GlobalBuffer_line.split()[-1])
                pJ_DRAM = float(pJ_DRAM_line.split()[-1])
                pJ_per_compute = float(pJ_line.split()[-1])

                tops_per_watt = computes / (pJ_per_compute * cycles)

                folder = os.path.relpath(root, root_directory)

                rows.append({
                    'Folder': folder,
                    'TOPS/W': tops_per_watt,
                    'Cycles': cycles,
                    'Computes': computes,
                    'pJ_LMAC': pJ_MACC,
                    'pJ_PEWeightRegs': pJ_PEWeightRegs,
                    'pJ_PEAccuBuffer': pJ_PEAccuBuffer,
                    'pJ_PEInputBuffer': pJ_PEInputBuffer,
                    'pJ_GlobalBuffer': pJ_GlobalBuffer,
                    'pJ_DRAM': pJ_DRAM,
                    'pJ/Compute': pJ_per_compute,
                    'Energy': energy,
                    'Utilization': utilization,
                    'EDP': edp
                })

df = pd.DataFrame(rows)

# save csv
df.to_csv(csv_filepath, index=False)

print("CSV file saved to:", csv_filepath)