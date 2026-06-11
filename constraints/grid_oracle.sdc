# SDC Timing Constraints — SkyWater 130nm / TinyTapeout 7

# Primary clock 20 MHz
create_clock -name ui_clk -period 50 [get_ports ui_clk]
set_clock_uncertainty 2 [get_clocks ui_clk]

# Generated clocks
create_generated_clock -name grid_clk -source [get_ports ui_clk] \
    -divide_by 4 [get_pins u_grid_clk_div/div_clk_reg/Q]
create_generated_clock -name projection_clk -source [get_ports ui_clk] \
    -divide_by 16 [get_pins u_proj_clk_div/div_clk_reg/Q]
create_generated_clock -name readout_clk -source [get_ports ui_clk] \
    -divide_by 64 [get_pins u_read_clk_div/div_clk_reg/Q]

# Input / output delays
set_input_delay  -clock ui_clk -max 5 [get_ports ui_in*]
set_input_delay  -clock ui_clk -min 2 [get_ports ui_in*]
set_input_delay  -clock sclk  -max 5 [get_ports sf_rdata]
set_output_delay -clock ui_clk -max 5 [get_ports uo_out*]
set_output_delay -clock ui_clk -min 2 [get_ports uo_out*]
set_output_delay -clock sclk  -max 5 [get_ports sf_wdata]

# False paths
set_false_path -from [get_ports ui_rstb]
set_false_path -from [get_ports uio_in]
set_false_path -to   [get_ports uio_out]

# Max transition / capacitance / fanout
set_max_transition  1.5  [all_inputs]
set_max_capacitance 0.05 [all_outputs]
set_max_fanout      16   [all_outputs]

# Multicycle paths (grid evolution — slow logic)
set_multicycle_path -setup 4 \
    -from [get_cells -hierarchical -filter {name =~ *u_grid_core*}] \
    -to   [get_cells -hierarchical -filter {name =~ *u_grid_core*}]

# Clock domain crossings
set_clock_groups -asynchronous \
    -group [get_clocks ui_clk] \
    -group [get_clocks grid_clk] \
    -group [get_clocks projection_clk] \
    -group [get_clocks readout_clk]
