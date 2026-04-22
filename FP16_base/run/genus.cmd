# Cadence Genus(TM) Synthesis Solution, Version 21.14-s082_1, built Jun 23 2022 14:32:08

# Date: Wed Apr 15 16:56:07 2026
# Host: nanodc.iitgn.ac.in (x86_64 w/Linux 3.10.0-1160.76.1.el7.x86_64) (32cores*64cpus*1physical cpu*AMD EPYC 7532 32-Core Processor 512KB)
# OS:   CentOS Linux release 7.9.2009 (Core)

source ../mul_vcd.tcl
cd ..
cd ..
source ../mul_vcd.tcl
set precision_cases {

    {fp16_mul.vcd    "fp16"}
  
}
foreach cfg $precision_cases {

    set vcd_file   [lindex $cfg 0]
    set tag        [lindex $cfg 1]


    set vcd_path   "../vcd/$vcd_file"
    set report_dir "../reports/$tag"

    # Skip if VCD doesn't exist
    if {![file exists $vcd_path]} {
        puts "WARNING: VCD not found for $tag  skipping"
        continue
    }

    puts ""
    puts "============================================================"
    puts " Running power analysis: 
    puts "============================================================"


    # Create report directory
    file mkdir $report_dir

    # Load switching activity from precision-specific VCD
    read_vcd -static \
             -vcd_scope tb_fp16_multiplier.dut \
             $vcd_path

    propagate_activity
    report_activity > $report_dir/activity_${tag}.txt


    # ---- Reports for this precision ----
    report_power          > $report_dir/power_flat_${tag}.txt
    report_power -hierarchy all \
                          > $report_dir/power_hier_${tag}.txt
    report_gates          > $report_dir/gates_${tag}.txt
    report_area           > $report_dir/area_${tag}.txt
    report_timing         > $report_dir/timing_${tag}.txt
    report_clock_gating   > $report_dir/clock_gating_${tag}.txt

    puts "  -> Reports written to $report_dir/"
}
check_design > design_check.txt
puts ""
puts "============================================================"
puts " All precision cases complete."
puts "============================================================"
cd ..
cd ..
