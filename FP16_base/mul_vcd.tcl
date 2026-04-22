# ============================================================
# Step 1: Set library paths
# ============================================================
set_attr init_lib_search_path /home/zaqi/DECODER_ZAQI/lib
set_attr hdl_search_path      /home/zaqi/Project_2026_final/FP16_base/rtl
set_attr library              uk65lscllmvbbr_120c25_tc_ccs.lib

# ============================================================
# Clock gating (MUST be before elaborate)
# ============================================================
set_attr lp_insert_clock_gating true

# ============================================================
# Step 2: Read HDL
# ============================================================
read_hdl -sv {fp16_multiplier_pipe.sv}
set top_module fp16_multiplier_pipe

# ============================================================
# Step 3: Elaborate
# ============================================================
elaborate

set_attr lp_clock_gating_min_flops 2 [find /designs/fp16_multiplier_pipe]

# ============================================================
# Step 4: Read SDC constraints
# ============================================================
current_design fp16_multiplier_pipe
read_sdc ../sdc/original.sdc

# ============================================================
# Step 5: Synthesis (generic + map + opt) — done ONCE
# ============================================================
set_attr syn_generic_effort high
syn_generic

syn_map

set_attr syn_opt_effort high
syn_opt
# ============================================================
# Write synthesised netlist ONCE (shared across all precisions)
# ============================================================
write_hdl > top_recon_multiplier.v
write_sdc > top_recon_multiplier_umc65nm.sdc
write_sdf > top_recon_multiplier_umc65nm.sdf

# ============================================================
# Step 6: Define precision configurations
#   Format: {total_bits exp_bits vcd_filename report_tag}
# ============================================================
set precision_cases {

    {fp16_mul_1000.vcd    "fp16_1000"}
  
}

# ============================================================
# Step 7: Per-precision power analysis loop
# ============================================================
foreach cfg $precision_cases {

    set vcd_file   [lindex $cfg 0]
    set tag        [lindex $cfg 1]


    set vcd_path   "../vcd/$vcd_file"
    set report_dir "../reports/$tag"

    # Skip if VCD doesn't exist
    if {![file exists $vcd_path]} {
        puts "WARNING: VCD not found for $tag ($vcd_path) — skipping"
        continue
    }

    puts ""
    puts "============================================================"
    puts " Running power analysis:"
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

# ============================================================
# Step 8: Design check and summary (once, after all runs)
# ============================================================
check_design > design_check.txt

puts ""
puts "============================================================"
puts " All precision cases complete."
puts "============================================================"

exit
