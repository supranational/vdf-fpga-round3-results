# Tcl script run before place_design

puts "### Running script [file tail [info script]]"

set STEP {place_design.pre}

# save checkpoint
write_checkpoint ${STEP}.dcp

# Required for SDAccel to prevent this:
# ERROR: [Place 30-718] Sub-optimal placement for an MMCM/PLL-BUFGCE-MMCM/PLL cascade pair.If this sub optimal condition is acceptable for this design, you may use the CLOCK_DEDICATED_ROUTE constraint in the .xdc file to demote this message to a WARNING. However, the use of this override is highly discouraged. These examples can be used directly in the .xdc file to override this clock rule.
set_property CLOCK_DEDICATED_ROUTE ANY_CMT_COLUMN [get_nets WRAPPER_INST/SH/kernel_clks_i/clkwiz_kernel_clk0/inst/CLK_CORE_DRP_I/clk_inst/clk_out1]

#---------------------------------------------------------------------------------------------------
# placement constraints

# we want DSP utilization to be ~equal in mid and upper die

# in mult, find 964 DSP that generate the lowest bit values (this is about 40% of its 2409 total DSP)
set limit 944
set low_DSPs   {}
set other_DSPs {}
for {set q 0} {$q < 61} {incr q} {
    for {set r 0} {$r < 29} {incr r} {
	set cellname "WRAPPER_INST/CL/vdf_1/inst/inst_wrapper/inst_kernel/msu/modsqr/modsqr/mult/gens.loop_q[${q}].loop_r[${r}].mult_inst/p__0"
	# MSB generated by this DSP
	set maxbit [expr ((${q} + 1) * 17) + ((${r} + 1) * 26)]

	if {$maxbit <= $limit} {
	    lappend low_DSPs $cellname
	} else {
	    lappend other_DSPs $cellname
	}
    }
}
for {set s 0} {$s < 40} {incr s} {
    for {set t 0} {$t < 16} {incr t} {
	set cellname "WRAPPER_INST/CL/vdf_1/inst/inst_wrapper/inst_kernel/msu/modsqr/modsqr/mult/gens.loop_s[${s}].loop_t[${t}].mult_inst/p__0"
	# MSB generated by this DSP
	set maxbit [expr (((${t} + 1) * 17) + (26*29)) + ((${s} + 1) * 26)]

	if {$maxbit <= $limit} {
	    lappend low_DSPs $cellname
	} else {
	    lappend other_DSPs $cellname
	}
    }
}

# put low 40% in middle die
##puts "# putting [llength $low_DSPs] DSP into middle die"
##add_cells_to_pblock [get_pblocks pblock_dynamic_SLR1] [get_cells ${low_DSPs}]

# put other 60% of mult DSP in upper die
##puts "# putting [llength $other_DSPs] DSP into top die"
##add_cells_to_pblock [get_pblocks pblock_dynamic_SLR2] [get_cells ${other_DSPs}]

#---------------------------------------------------------------------------------------------------

# reports

report_drc -ruledecks {default} > report_drc.${STEP}.rpt
