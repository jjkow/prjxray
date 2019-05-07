# WARNING: this is somewhat paramaterized, but is only tested on A50T/A35T with the traditional ROI
# Your ROI should at least have a SLICEL on the left

set WITH_ZYNQ "$::env(WITH_ZYNQ)"
set WITH_TEST1 "$::env(WITH_TEST1)"
set WITH_TEST2 "$::env(WITH_TEST2)"
set WITH_BLACKBOX "$::env(WITH_BLACKBOX)"

# Number of package inputs going to ROI
set DIN_N 1
if { [info exists ::env(DIN_N) ] } {
    set DIN_N "$::env(DIN_N)"
}
# Number of ROI outputs going to package
set DOUT_N 3
if { [info exists ::env(DOUT_N) ] } {
    set DOUT_N "$::env(DOUT_N)"
}
# How many rows between pins
# Reduces routing pressure
set PITCH 3
if { [info exists ::env(PITCH) ] } {
    set PITCH "$::env(PITCH)"
}

if { [info exists ::env(XRAY_ROI_HCLK)] } {
    set XRAY_ROI_HCLK "$::env(XRAY_ROI_HCLK)"
} else {
    puts "WARNING: No HCLK has been set"
}

# Setting all the PIPs for DIN and DOUT
if { [info exists ::env(XRAY_ROI_DIN_LPIP)] } {
    set DIN_LPIP "$::env(XRAY_ROI_DIN_LPIP)"
} else { puts "Warning: No left pip for DIN has been set"  }

if { [info exists ::env(XRAY_ROI_DIN_RPIP)] } {
    set DIN_RPIP "$::env(XRAY_ROI_DIN_RPIP)"
} else { puts "Warning: No right pip for DIN has been set"  }

if { [info exists ::env(XRAY_ROI_DOUT_LPIP)] } {
    set DOUT_LPIP "$::env(XRAY_ROI_DOUT_LPIP)"
} else { puts "Warning: No left pip for DOUT has been set"  }

if { [info exists ::env(XRAY_ROI_DOUT_RPIP)] } {
    set DOUT_RPIP "$::env(XRAY_ROI_DOUT_RPIP)"
} else { puts "Warning: No right pip for DOUT has been set"  }

# Setting all INT_L/R tiles for DIN and DOUT X values
if { [info exists ::env(XRAY_ROI_DIN_INT_L_X)] } {
    set DIN_INT_L_X "$::env(XRAY_ROI_DIN_INT_L_X)"
} else { puts "Warning: No INT_L for DIN has been set"  }

if { [info exists ::env(XRAY_ROI_DIN_INT_R_X)] } {
    set DIN_INT_R_X "$::env(XRAY_ROI_DIN_INT_R_X)"
} else { puts "Warning: No INT_R for DIN has been set"  }

if { [info exists ::env(XRAY_ROI_DOUT_INT_L_X)] } {
    set DOUT_INT_L_X "$::env(XRAY_ROI_DOUT_INT_L_X)"
} else { puts "Warning: No INT_L for DOUT has been set"  }

if { [info exists ::env(XRAY_ROI_DOUT_INT_R_X)] } {
    set DOUT_INT_R_X "$::env(XRAY_ROI_DOUT_INT_R_X)"
} else { puts "Warning: No INT_R for DOUT has been set"  }

# X12 in the ROI, X10 just to the left
# Start at bottom left of ROI and work up
# (IOs are to left)
# SLICE_X12Y100:SLICE_X27Y149
# set X_BASE 12
set XRAY_ROI_X0 [lindex [split [lindex [split "$::env(XRAY_ROI)" Y] 0] X] 1]
set XRAY_ROI_X1 [lindex [split [lindex [split "$::env(XRAY_ROI)" X] 2] Y] 0]
set XRAY_ROI_Y0 [lindex [split [lindex [split "$::env(XRAY_ROI)" Y] 1] :] 0]
set XRAY_ROI_Y1 [lindex [split "$::env(XRAY_ROI)" Y] 2]

set X_BASE $XRAY_ROI_X0
set Y_BASE $XRAY_ROI_Y0

set Y_CLK_BASE $Y_BASE
# Clock lut in middle
set Y_DIN_BASE [expr "$Y_CLK_BASE + $PITCH"]
# Sequential
# set Y_DOUT_BASE [expr "$Y_DIN_BASE + $DIN_N"]
# At top. This relieves routing pressure by spreading things out
# Note: can actually go up one more if we want
set Y_DOUT_BASE [expr "$XRAY_ROI_Y1 - $DOUT_N * $PITCH"]

# Y_OFFSET: offset amount to shift the components on the y column to avoid hard blocks
set Y_OFFSET 24

set part "$::env(XRAY_PART)"
set pincfg ""
if { [info exists ::env(XRAY_PINCFG) ] } {
    set pincfg "$::env(XRAY_PINCFG)"
}
#set roiv "../test.v"
#if { [info exists ::env(XRAY_ROIV) ] } {
#    set roiv "$::env(XRAY_ROIV)"
#}
#set roiv_trim [string map {.v v} $roiv]

puts "Environment"
puts "  XRAY_ROI: $::env(XRAY_ROI)"
puts "  X_BASE: $X_BASE"
puts "  Y_DIN_BASE: $Y_DIN_BASE"
puts "  Y_CLK_BASE: $Y_CLK_BASE"
puts "  Y_DOUT_BASE: $Y_DOUT_BASE"
puts "  WITH_ZYNQ: $WITH_ZYNQ"
puts "  WITH_TEST1: $WITH_TEST1"
puts "  WITH_TEST2: $WITH_TEST2"
puts "  WITH_BLACKBOX: $WITH_BLACKBOX"

source ../../../utils/utils.tcl

if { $WITH_ZYNQ eq 0 } {
    create_project -force -part $::env(XRAY_PART) design design
    if { $WITH_BLACKBOX eq 1 } {
        set roiv "../blackbox.v"
    } elseif { $WITH_TEST1 eq 1 } {
        set roiv "../test1.v"
    } elseif { $WITH_TEST2 eq 1 } {
        set roiv "../test2.v"
    } else {
        error "No BLACKBOX nor TEST1 nor TEST2 is set!"
    }

    read_verilog ../roi.v
    set top_module_name "roi"
    set module_name "test"
    read_verilog $roiv

    set fixed_xdc ""
    if { [info exists ::env(XRAY_FIXED_XDC) ] } {
        set fixed_xdc "$::env(XRAY_FIXED_XDC)"
    }
    
    synth_design -top $top_module_name -flatten_hierarchy none -verilog_define DIN_N=$DIN_N -verilog_define DOUT_N=$DOUT_N
} else {

    # TODO
    # Create Project for Zybo board
    create_project -force -part $::env(XRAY_PART) design design
    set proj_dir [get_property directory [current_project]]
    set obj [current_project]
    set_property -name "board_part" -value "digilentinc.com:zybo:part0:1.0" -objects $obj
    set_property -name "dsa.board_id" -value "zybo" -objects $obj
    set_property target_language Verilog [current_project]
    
    # Prepare BD with PS7 ZYNQ
    create_bd_design "design_0"
    open_bd_design {./design/design.srcs/sources_1/bd/design_0/design_0.bd}
    create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
    set_property -dict [list CONFIG.preset {ZC702}] [get_bd_cells processing_system7_0]
    apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
    connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
    
    if { $WITH_BLACKBOX eq 1 } {
        set roiv "../blackbox.v"
    } elseif { $WITH_TEST1 eq 1 } {
        set roiv "../test1.v"
    } elseif { $WITH_TEST2 eq 1 } {
        set roiv "../test2.v"
    } else {
        error "No BLACKBOX nor TEST1 nor TEST2 is set!"
    }

    read_verilog ../roi.v
    set top_module_name "roi"
    set module_name "test"
    read_verilog $roiv

    create_bd_cell -type module -reference $top_module_name $top_module_name
    apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins $top_module_name/clk]
    #make_bd_pins_external  [get_bd_pins $module_name/din]
    make_bd_pins_external  [get_bd_pins $top_module_name/dout]
    make_bd_pins_external  [get_bd_pins $top_module_name/blinky]
    update_compile_order -fileset sources_1
    
    # Prepare everything to synth
    set_property synth_checkpoint_mode Hierarchical [get_files ./design/design.srcs/sources_1/bd/design_0/design_0.bd]
    make_wrapper -files [get_files ./design/design.srcs/sources_1/bd/design_0/design_0.bd] -top
    add_files -norecurse ./design/design.srcs/sources_1/bd/design_0/hdl/design_0_wrapper.v
    set_property top design_0_wrapper [current_fileset]
    update_compile_order -fileset sources_1
    
    launch_runs synth_1 -jobs 4
    wait_on_run synth_1
    open_run synth_1 -name synth_1
}

# Map of top level net names to IOB pin names
array set net2pin [list]

if {$part eq "xc7z010clg400-1"} {
    if {$pincfg eq "ZYBOZ7-SWBUT"} {
        # https://github.com/Digilent/digilent-xdc/blob/master/Zybo-Z7-Master.xdc

        # Slide switches and buttons
        # TODO: Import XDC?

        set outs "M14 M15 G14"
        set blinky "D18"

        if { $WITH_ZYNQ eq 0 } {
            # 125 MHz CLK onboard
            set pin "K17"
            set net2pin(clk) $pin
        }

        #set net2pin(din) $din

        for {set i 0} {$i < $DOUT_N} {incr i} {
            set pin [lindex $outs $i]
            set net2pin(dout[$i]) $pin
        }

        set net2pin(blinky) $blinky

        # setting Y_OFFSET to zero only for zynq parts
        set Y_OFFSET 0

    } else {
        error "Unsupported config $pincfg"
    }
} else {
    error "Pins: unsupported part $part"
}

# Now actually apply the pin definitions
puts "Applying pin definitions"
foreach {net pin} [array get net2pin] {
    puts "  Net $net to pin $pin"
    set_property -dict "PACKAGE_PIN $pin IOSTANDARD LVCMOS33" [get_ports $net]
}

write_checkpoint -force synth.dcp

create_pblock roi
set_property EXCLUDE_PLACEMENT 1 [get_pblocks roi]
set_property CONTAIN_ROUTING true [get_pblocks roi]
# Because the Blackbox is under design_0_wrapper, we do not have roi cells
if { $WITH_ZYNQ eq 0 } {
    set_property DONT_TOUCH true [get_cells $module_name]
    add_cells_to_pblock [get_pblocks roi] [get_cells $module_name]
    set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_IBUF]
} else {
    set_property DONT_TOUCH true [get_cells design_0_i/$top_module_name/inst/$module_name]
    add_cells_to_pblock [get_pblocks roi] [get_cells design_0_i/$top_module_name/inst/$module_name]
    set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets design_0_i/processing_system7_0/inst/FCLK_CLK0]
}
resize_pblock [get_pblocks roi] -add "$::env(XRAY_ROI)"

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
#set_property BITSTREAM.GENERAL.PERFRAMECRC YES [current_design]

proc loc_roi_clk_left {ff_x ff_y top_module_name module_name WITH_ZYNQ} {
    # Place an ROI clk on the left edge of the ROI
    # It doesn't actually matter where we place this, just do it to keep things neat looking
    # ff_x: ROI SLICE X position
    # ff_yy: row primitives will be placed at

    set slice_ff "SLICE_X${ff_x}Y${ff_y}"

    # Fix FFs to guide route in
    # TODO non ZYNQ
    if { $WITH_ZYNQ eq 0 } {
        set cell [get_cells "${module_name}/clk_reg_reg"]
    } else {
        set cell [get_cells "design_0_i/$top_module_name/inst/$module_name/clk_reg_reg"]
    }
    set_property LOC $slice_ff $cell
    set_property BEL AFF $cell
}

# Not used for now
#proc loc_lut_in {index lut_x lut_y} {
#    # Place a lut at specified coordinates in BEL A
#    # index: input bus index
#    # lut_x: SLICE X position
#    # lut_y: SLICE Y position
#
#    set slice_lut "SLICE_X${lut_x}Y${lut_y}"
#
#    # Fix LUTs near the edge
#    set cell [get_cells "roi/ins[$index].lut"]
#    set_property LOC $slice_lut $cell
#    set_property BEL A6LUT $cell
#}

proc loc_lut_out {index lut_x lut_y top_module_name module_name WITH_ZYNQ} {
    # Place a lut at specified coordinates in BEL A
    # index: input bus index
    # lut_x: SLICE X position
    # lut_y: SLICE Y position

    set slice_lut "SLICE_X${lut_x}Y${lut_y}"

    # Fix LUTs near the edge
    if { $WITH_ZYNQ eq 0 } {
        set cell [get_cells "${module_name}/outs[$index].lut"]
    } else {
        set cell [get_cells "design_0_i/$top_module_name/inst/$module_name/outs[$index].lut"]
    }
    set_property LOC $slice_lut $cell
    set_property BEL A6LUT $cell
}

proc net_bank_left {net} {
    # return 1 if net goes to a leftmost die IO bank
    # return 0 if net goes to a rightmost die IO bank

    set bank [get_property IOBANK [get_ports $net]]
    set left_banks "14 15 16"
    set right_banks "34 35"

    # left
    if {[lsearch -exact $left_banks $bank] >= 0} {
        return 1
        # right
    } elseif {[lsearch -exact $right_banks $bank] >= 0} {
        return 0
    } else {
        error "Bad bank $bank"
    }
}

# Manual placement
set x $X_BASE

# Place ROI clock right after inputs
puts "Placing ROI clock"
loc_roi_clk_left $x $Y_CLK_BASE $top_module_name $module_name $WITH_ZYNQ

# Place ROI inputs - not used for now
#puts "Placing ROI inputs"
#set y_left $Y_DIN_BASE
## Shift y_right up to avoid PCIe block that makes routing hard.
#set y_right [expr {$Y_DIN_BASE + $Y_OFFSET}]
#for {set i 0} {$i < $DIN_N} {incr i} {
#    if {[net_bank_left "din[$i]"]} {
#        loc_lut_in $i $XRAY_ROI_X0 $y_left
#        set y_left [expr {$y_left + $PITCH}]
#    } else {
#        loc_lut_in $i $XRAY_ROI_X1 $y_right
#        set y_right [expr {$y_right + $PITCH}]
#    }
#}

# Place ROI outputs
set y_left $Y_DOUT_BASE
set y_right $Y_DOUT_BASE
puts "yleft: ${Y_DOUT_BASE}, yright: ${Y_DOUT_BASE}"
puts "Placing ROI outputs"
for {set i 0} {$i < $DOUT_N} {incr i} {
    if {[net_bank_left "dout[$i]"]} {
        loc_lut_out $i $XRAY_ROI_X0 $y_left $top_module_name $module_name $WITH_ZYNQ
        set y_left [expr {$y_left + $PITCH}]
    } else {
        loc_lut_out $i $XRAY_ROI_X1 $y_right $top_module_name $module_name $WITH_ZYNQ
        set y_right [expr {$y_right + $PITCH}]
    }
}


# Place everything
place_design
write_checkpoint -force placed.dcp

# Version with more error checking for missing end node
# Will do best effort in this case
proc route_via2 {net nodes} {
    # net: net as string
    # nodes: string list of one or more intermediate routing nodes to visit

    set net [get_nets $net]
    # Start at the net source
    set fixed_route [get_nodes -of_objects [get_site_pins -filter {DIRECTION == OUT} -of_objects $net]]
    # End at the net destination
    # For sone reason this doesn't always show up
    set site_pins [get_site_pins -filter {DIRECTION == IN} -of_objects $net]
    if {$site_pins eq ""} {
        puts "WARNING: could not find end node"
        #error "Could not find end node"
    } else {
        set end_node [get_nodes -of_objects]
        lappend nodes [$end_node]
    }

    puts ""
    puts "Routing net $net:"

    foreach to_node $nodes {
        if {$to_node eq ""} {
            error "Empty node"
        }

        # Node string to object
        set to_node [get_nodes -of_objects [get_wires $to_node]]
        # Start at last routed position
        set from_node [lindex $fixed_route end]
        # Let vivado do heavy liftin in between
        set route [find_routing_path -quiet -from $from_node -to $to_node]
        if {$route == ""} {
            # Some errors print a huge route
            puts [concat [string range "  $from_node -> $to_node" 0 1000] ": no route found - assuming direct PIP"]
            lappend fixed_route $to_node
        } {
            puts [concat [string range "  $from_node -> $to_node: $route" 0 1000] "routed"]
            set fixed_route [concat $fixed_route [lrange $route 1 end]]
        }
        set_property -quiet FIXED_ROUTE $fixed_route $net
    }

    set_property -quiet FIXED_ROUTE $fixed_route $net
    puts ""
}

# Return the wire on the ROI boundary
proc node2wire {node} {
    set wires [get_wires -of_objects [get_nodes $node]]
    set wire [lsearch -inline $wires *VBRK*]
    return $wire
}

proc write_grid_roi {fp} {
    puts $fp "GRID_X_MIN = $::env(XRAY_ROI_GRID_X1)"
    puts $fp "GRID_X_MAX = $::env(XRAY_ROI_GRID_X2)"
    puts $fp "GRID_Y_MIN = $::env(XRAY_ROI_GRID_Y1)"
    puts $fp "GRID_Y_MAX = $::env(XRAY_ROI_GRID_Y2)"
}

set fp [open "design_info.txt" w]
write_grid_roi $fp
close $fp

# XXX: maybe add IOB?
set fp [open "design.txt" w]
set fp_wires [open "design_pad_wires.txt" w]
puts $fp "name node pin wire"

# Manual routing
set x $X_BASE

# No routing strictly needed for clk
# It will go to high level interconnect that goes everywhere
# But we still need to record something, so lets force a route
# FIXME: very ROI specific
set node "$XRAY_ROI_HCLK"
set wire [node2wire $node]
if { $WITH_ZYNQ eq 0 } {
    route_via2 "clk_IBUF_BUFG" "$node"
    set net "clk"
    set pin "$net2pin($net)"
    puts $fp "$net $node $pin $wire"
} else {
    route_via2 "design_0_i/processing_system7_0/FCLK_CLK0" "$node"
}

puts "Routing ROI inputs - not used for now"
## Arbitrary offset as observed
#set y_left $Y_DIN_BASE
#set y_right [expr {$Y_DIN_BASE + $Y_OFFSET}]
#for {set i 0} {$i < $DIN_N} {incr i} {
#    # needed to force routes away to avoid looping into ROI
#    if {[net_bank_left "din[$i]"]} {
#        set node "INT_L_X${DIN_INT_L_X}Y${y_left}/${DIN_LPIP}"
#        route_via2 "din_IBUF[$i]" "$node"
#        set y_left [expr {$y_left + $PITCH}]
#    } else {
#        set node "INT_R_X${DIN_INT_R_X}Y${y_right}/${DIN_RPIP}"
#        route_via2 "din_IBUF[$i]" "$node"
#        set y_right [expr {$y_right + $PITCH}]
#    }
#    set net "din[$i]"
#    set pin "$net2pin($net)"
#    set wire [node2wire $node]
#    puts $fp "$net $node $pin $wire"

#    set wires [get_wires -of_objects [get_nets "din_IBUF[$i]"]]
#    puts $fp_wires "$net $pin $wires"
#}

puts "Routing ROI outputs"
# Arbitrary offset as observed
set y_left [expr {$Y_DOUT_BASE + 0}]
set y_right [expr {$Y_DOUT_BASE + 0}]
for {set i 0} {$i < $DOUT_N} {incr i} {
    if {[net_bank_left "dout[$i]"]} {
        set node "INT_L_X${DOUT_INT_L_X}Y${y_left}/${DOUT_LPIP}"
        if { $WITH_ZYNQ eq 0 } {
            route_via2 "$module_name/dout[$i]" "$node"
        } else {
            route_via2 "design_0_i/$top_module_name/dout[$i]" "$node"
        } 
        set y_left [expr {$y_left + $PITCH}]
        # XXX: only care about right ports on Arty
    } else {
        set node "INT_R_X${DOUT_INT_R_X}Y${y_right}/${DOUT_RPIP}"
        if { $WITH_ZYNQ eq 0 } {
            route_via2 "$module_name/dout[$i]" "$node"
        } else {
            route_via2 "design_0_i/$top_module_name/dout[$i]" "$node"
        } 
        set y_right [expr {$y_right + $PITCH}]
    }
    set net "dout[$i]"
    set pin "$net2pin($net)"
    set wire [node2wire $node]
    puts $fp "$net $node $pin $wire"

    if { $WITH_ZYNQ eq 0 } {
        set wires [get_wires -of_objects [get_nets "$module_name/dout[$i]"]]
    } else {
        set wires [get_wires -of_objects [get_nets "design_0_i/$top_module_name/dout[$i]"]]
    }
    puts $fp_wires "$net $pin $wires"
}

close $fp
close $fp_wires

puts "routing design"
route_design

# Don't set for user designs
# Makes things easier to debug
#set_property IS_ROUTE_FIXED 1 [get_nets -hierarchical]
#set_property IS_LOC_FIXED 1 [get_cells -hierarchical]
#set_property IS_BEL_FIXED 1 [get_cells -hierarchical]
write_xdc -force fixed.xdc

write_checkpoint -force design.dcp
#set_property BITSTREAM.GENERAL.DEBUGBITSTREAM YES [current_design]
write_bitstream -force design.bit
