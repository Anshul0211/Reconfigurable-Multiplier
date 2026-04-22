set sdc_version 2.0
set clkPeriod 3
set_units -capacitance 1000fF
set_units -time 1000ps

current_design reconfig_fp_top

# Clock
create_clock -name "clk" -period $clkPeriod [get_ports clk]
set_clock_transition 0.05 [get_clocks clk]

# Input/Output delays — exclude clock from all_inputs
set data_inputs [remove_from_collection [all_inputs] [get_ports clk]]

set_input_delay  -clock [get_clocks clk] -max 0.460 $data_inputs
set_output_delay -clock [get_clocks clk] -max 0.460 [all_outputs]

# Drive and load
set_input_transition 0.1 $data_inputs
set_load 0.01 [all_outputs]

# Clock gating
set_clock_gating_check -setup 0.5
