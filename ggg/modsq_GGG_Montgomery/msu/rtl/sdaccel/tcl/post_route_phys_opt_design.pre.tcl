# Tcl script run before post_route_phys_opt_design

puts "### Running script [file tail [info script]]"

set STEP {post_route_phys_opt_design.pre}

#---------------------------------------------------------------------------------------------------
# enable bypass

# turn on bypass path
set_case_analysis 1 \
    [get_pins \
	 -of_object [get_cells -hier -filter {IS_SEQUENTIAL == true && NAME =~ *modsqr*/bypass_reg* }] \
	 -filter {DIRECTION == OUT}]

# these flops are now bypassed, so prevent bogus timing reports ending at them
set_false_path -to [get_clocks modsqr_clk_phase_05]
set_false_path -to [get_clocks modsqr_clk_phase_08]
set_false_path -to [get_clocks modsqr_clk_phase_10]

#---------------------------------------------------------------------------------------------------
