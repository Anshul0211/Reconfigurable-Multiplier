set_attr init_lib_search_path /home/zaqi/DECODER_ZAQI/lib
set_attr hdl_search_path /home/zaqi/RECON_MULTIPLIER_FP9/run
set_attr library uk65lscllmvbbr_120c25_tc_ccs.lib

#Step 2: Read netlist
read_hdl {reconfig_fp_top.v}
set top_module reconfig_fp_top


#Step 3: Elaborate/connect all modules
elaborate

set_dont_touch {top_recon_multiplier}  

#Step 4: Read constraints
#read_sdc ../sdc/new.sdc
read_sdc top_recon_multiplier_umc65nm.sdc

current_design top_recon_multiplier

read_vcd -static -vcd_scope reconfig_fp_top.dut ../vcd/fp_9_4.vcd

propagate_activity
report_activity > activity_summary_post.txt

#Step 10: Report final results
report_area > area_post_synth.txt
report_power > power_post_synth.txt
report_timing > timing_post_synth.txt


write_hdl > top_recon_multiplier_nul.v
write_sdc > top_recon_multiplier_nul_umc65nm.sdc  
write_sdf > top_recon_multiplier_nul_umc65nm.sdf

exit
