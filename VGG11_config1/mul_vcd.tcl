# ============================================================
# Step 1: Set library paths
# ============================================================
set_attr init_lib_search_path /home/zaqi/DECODER_ZAQI/lib
set_attr hdl_search_path      /home/zaqi/Project_2026_final/VGG11_config1/rtl
set_attr library              uk65lscllmvbbr_120c25_tc_ccs.lib

# ============================================================
# Clock gating (MUST be before elaborate)
# ============================================================
set_attr lp_insert_clock_gating true

# ============================================================
# Step 2: Read HDL
# ============================================================
read_hdl -sv {reconfig_fp_top.sv}
set top_module reconfig_fp_top

# ============================================================
# Step 3: Elaborate
# ============================================================
elaborate

set_attr lp_clock_gating_min_flops 2 [find /designs/reconfig_fp_top]

# ============================================================
# Step 4: Read SDC constraints
# ============================================================
current_design reconfig_fp_top
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
    {3   1   fp_3_1.vcd    "3b_1e"}
    {4   1   fp_4_1.vcd    "4b_1e"}
    {5   1   fp_5_1.vcd    "5b_1e"}
    {6   1   fp_6_1.vcd    "6b_1e"}
    {7    2   fp_7_2.vcd    "7b_2e"}
    {7    4   fp_7_4.vcd    "7b_4e"}
    {8    3   fp_8_3.vcd    "8b_3e"}
    {15    4   fp_15_4.vcd    "15b_4e"}
}

# ============================================================
# Step 7: Per-precision power analysis loop
# ============================================================
foreach cfg $precision_cases {
    set total_bits [lindex $cfg 0]
    set exp_bits   [lindex $cfg 1]
    set vcd_file   [lindex $cfg 2]
    set tag        [lindex $cfg 3]
    set man_bits   [expr {$total_bits - $exp_bits - 1}]

    set vcd_path   "../vcd/$vcd_file"
    set report_dir "../reports/$tag"

    # Skip if VCD doesn't exist
    if {![file exists $vcd_path]} {
        puts "WARNING: VCD not found for $tag ($vcd_path) — skipping"
        continue
    }

    puts ""
    puts "============================================================"
    puts " Running power analysis: total=$total_bits  exp=$exp_bits  man=$man_bits"
    puts "============================================================"

    # Create report directory
    file mkdir $report_dir

    reset_switching_activity

    # Load switching activity from precision-specific VCD
    read_vcd \
             -vcd_scope tb_fp.dut \
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
