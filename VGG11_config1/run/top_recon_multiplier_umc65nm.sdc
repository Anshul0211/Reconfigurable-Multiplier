# ####################################################################

#  Created by Genus(TM) Synthesis Solution 21.14-s082_1 on Tue Apr 14 13:45:59 EDT 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design reconfig_fp_top

create_clock -name "clk" -period 3.0 -waveform {0.0 1.5} [get_ports clk]
set_clock_transition 0.05 [get_clocks clk]
set_load -pin_load 0.01 [get_ports ready]
set_load -pin_load 0.01 [get_ports valid]
set_load -pin_load 0.01 [get_ports {result[15]}]
set_load -pin_load 0.01 [get_ports {result[14]}]
set_load -pin_load 0.01 [get_ports {result[13]}]
set_load -pin_load 0.01 [get_ports {result[12]}]
set_load -pin_load 0.01 [get_ports {result[11]}]
set_load -pin_load 0.01 [get_ports {result[10]}]
set_load -pin_load 0.01 [get_ports {result[9]}]
set_load -pin_load 0.01 [get_ports {result[8]}]
set_load -pin_load 0.01 [get_ports {result[7]}]
set_load -pin_load 0.01 [get_ports {result[6]}]
set_load -pin_load 0.01 [get_ports {result[5]}]
set_load -pin_load 0.01 [get_ports {result[4]}]
set_load -pin_load 0.01 [get_ports {result[3]}]
set_load -pin_load 0.01 [get_ports {result[2]}]
set_load -pin_load 0.01 [get_ports {result[1]}]
set_load -pin_load 0.01 [get_ports {result[0]}]
group_path -weight 1.000000 -name cg_enable_group_clk -through [list \
  [get_pins RC_CG_HIER_INST1/enable]  \
  [get_pins RC_CG_HIER_INST1/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST3/enable]  \
  [get_pins RC_CG_HIER_INST3/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST4/enable]  \
  [get_pins RC_CG_HIER_INST4/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST5/enable]  \
  [get_pins RC_CG_HIER_INST5/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST6/enable]  \
  [get_pins RC_CG_HIER_INST6/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST1/enable]  \
  [get_pins RC_CG_HIER_INST1/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST3/enable]  \
  [get_pins RC_CG_HIER_INST3/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST4/enable]  \
  [get_pins RC_CG_HIER_INST4/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST5/enable]  \
  [get_pins RC_CG_HIER_INST5/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST6/enable]  \
  [get_pins RC_CG_HIER_INST6/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST1/enable]  \
  [get_pins RC_CG_HIER_INST1/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST3/enable]  \
  [get_pins RC_CG_HIER_INST3/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST4/enable]  \
  [get_pins RC_CG_HIER_INST4/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST5/enable]  \
  [get_pins RC_CG_HIER_INST5/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST6/enable]  \
  [get_pins RC_CG_HIER_INST6/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST/enable]  \
  [get_pins RC_CG_DECLONE_HIER_INST/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST1/enable]  \
  [get_pins RC_CG_HIER_INST1/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST3/enable]  \
  [get_pins RC_CG_HIER_INST3/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST4/enable]  \
  [get_pins RC_CG_HIER_INST4/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST5/enable]  \
  [get_pins RC_CG_HIER_INST5/RC_CGIC_INST/E]  \
  [get_pins RC_CG_HIER_INST6/enable]  \
  [get_pins RC_CG_HIER_INST6/RC_CGIC_INST/E]  \
  [get_pins RC_CG_DECLONE_HIER_INST/enable]  \
  [get_pins RC_CG_DECLONE_HIER_INST/RC_CGIC_INST/E] ]
set_clock_gating_check -setup 0.5 
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports rst_n]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports start]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {total_bits[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {total_bits[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {total_bits[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {total_bits[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {total_bits[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {exp_bits[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {exp_bits[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {exp_bits[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {exp_bits[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[15]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[14]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[13]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[12]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[11]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[10]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[9]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[8]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {A[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[15]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[14]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[13]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[12]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[11]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[10]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[9]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[8]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {B[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports ready]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports valid]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[15]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[14]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[13]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[12]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[11]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[10]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[9]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[8]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[7]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[6]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[5]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[4]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[3]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[2]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[1]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 0.46 [get_ports {result[0]}]
set_input_transition 0.1 [get_ports rst_n]
set_input_transition 0.1 [get_ports start]
set_input_transition 0.1 [get_ports {total_bits[4]}]
set_input_transition 0.1 [get_ports {total_bits[3]}]
set_input_transition 0.1 [get_ports {total_bits[2]}]
set_input_transition 0.1 [get_ports {total_bits[1]}]
set_input_transition 0.1 [get_ports {total_bits[0]}]
set_input_transition 0.1 [get_ports {exp_bits[3]}]
set_input_transition 0.1 [get_ports {exp_bits[2]}]
set_input_transition 0.1 [get_ports {exp_bits[1]}]
set_input_transition 0.1 [get_ports {exp_bits[0]}]
set_input_transition 0.1 [get_ports {A[15]}]
set_input_transition 0.1 [get_ports {A[14]}]
set_input_transition 0.1 [get_ports {A[13]}]
set_input_transition 0.1 [get_ports {A[12]}]
set_input_transition 0.1 [get_ports {A[11]}]
set_input_transition 0.1 [get_ports {A[10]}]
set_input_transition 0.1 [get_ports {A[9]}]
set_input_transition 0.1 [get_ports {A[8]}]
set_input_transition 0.1 [get_ports {A[7]}]
set_input_transition 0.1 [get_ports {A[6]}]
set_input_transition 0.1 [get_ports {A[5]}]
set_input_transition 0.1 [get_ports {A[4]}]
set_input_transition 0.1 [get_ports {A[3]}]
set_input_transition 0.1 [get_ports {A[2]}]
set_input_transition 0.1 [get_ports {A[1]}]
set_input_transition 0.1 [get_ports {A[0]}]
set_input_transition 0.1 [get_ports {B[15]}]
set_input_transition 0.1 [get_ports {B[14]}]
set_input_transition 0.1 [get_ports {B[13]}]
set_input_transition 0.1 [get_ports {B[12]}]
set_input_transition 0.1 [get_ports {B[11]}]
set_input_transition 0.1 [get_ports {B[10]}]
set_input_transition 0.1 [get_ports {B[9]}]
set_input_transition 0.1 [get_ports {B[8]}]
set_input_transition 0.1 [get_ports {B[7]}]
set_input_transition 0.1 [get_ports {B[6]}]
set_input_transition 0.1 [get_ports {B[5]}]
set_input_transition 0.1 [get_ports {B[4]}]
set_input_transition 0.1 [get_ports {B[3]}]
set_input_transition 0.1 [get_ports {B[2]}]
set_input_transition 0.1 [get_ports {B[1]}]
set_input_transition 0.1 [get_ports {B[0]}]
set_wire_load_mode "top"
