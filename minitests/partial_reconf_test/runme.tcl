# WARNING: this is somewhat paramaterized, but is only tested on A50T/A35T with the traditional ROI
# Your ROI should at least have a SLICEL on the left

set WITH_ZYNQ "$::env(WITH_ZYNQ)"

# Number of package inputs going to ROI
set DIN_N 1
if { [info exists ::env(DIN_N) ] } {
    set DIN_N "$::env(DIN_N)"
}
# Number of ROI outputs going to package
set DOUT_N 4
if { [info exists ::env(DOUT_N) ] } {
    set DOUT_N "$::env(DOUT_N)"
}
# How many rows between pins
# Reduces routing pressure
set PITCH 1
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
set Y_DOUT_BASE [expr "$XRAY_ROI_Y1 - $DIN_N * $PITCH"]

# Y_OFFSET: offset amount to shift the components on the y column to avoid hard blocks
set Y_OFFSET 24

set part "$::env(XRAY_PART)"
set pincfg ""
if { [info exists ::env(XRAY_PINCFG) ] } {
    set pincfg "$::env(XRAY_PINCFG)"
}
set roiv "../test.v"
if { [info exists ::env(XRAY_ROIV) ] } {
    set roiv "$::env(XRAY_ROIV)"
}
set roiv_trim [string map {.v v} $roiv]

puts "Environment"
puts "  XRAY_ROI: $::env(XRAY_ROI)"
puts "  X_BASE: $X_BASE"
puts "  Y_DIN_BASE: $Y_DIN_BASE"
puts "  Y_CLK_BASE: $Y_CLK_BASE"
puts "  Y_DOUT_BASE: $Y_DOUT_BASE"
puts "  WITH_ZYNQ: $WITH_ZYNQ"

source ../../../utils/utils.tcl

if { $WITH_ZYNQ eq "0" } {
    create_project -force -part $::env(XRAY_PART) design design
    read_verilog ../blackbox.v
    read_verilog $roiv
    set fixed_xdc ""
    if { [info exists ::env(XRAY_FIXED_XDC) ] } {
        set fixed_xdc "$::env(XRAY_FIXED_XDC)"
    }
    
    synth_design -top blackbox -flatten_hierarchy none -verilog_define DIN_N=$DIN_N -verilog_define DOUT_N=$DOUT_N
} else {
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
    
    # ROI DEPENDENT ---
    # Add Blackbox
    read_verilog ../blackbox.v
    read_verilog $roiv
    create_bd_cell -type module -reference blackbox blackbox
    apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/processing_system7_0/FCLK_CLK0 (100 MHz)" }  [get_bd_pins blackbox/clk]
    make_bd_pins_external  [get_bd_pins blackbox/din]
    make_bd_pins_external  [get_bd_pins blackbox/dout]
    update_compile_order -fileset sources_1
    # --- ROI DEPENDENT
    
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
        set din "T16"
        set dout "M14 M15 G14 D18"

        if { $WITH_ZYNQ eq "0" } {
            # 125 MHz CLK onboard
            set pin "K17"
            set net2pin(clk) $pin
        }

        set net2pin(din) $din

        for {set i 0} {$i < $DOUT_N} {incr i} {
            set pin [lindex $dout $i]
            set net2pin(dout[$i]) $pin
        }

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

create_pblock roi
set_property EXCLUDE_PLACEMENT 1 [get_pblocks roi]
set_property CONTAIN_ROUTING true [get_pblocks roi]
# Because the Blackbox is under design_0_wrapper, we do not have roi cells
if { $WITH_ZYNQ eq 0 } {
    set_property DONT_TOUCH true [get_cells test]
    add_cells_to_pblock [get_pblocks roi] [get_cells test]
} else {
    set_property DONT_TOUCH true [get_cells design_0_i/blackbox]
    add_cells_to_pblock [get_pblocks roi] [get_cells design_0_i/blackbox]
}
resize_pblock [get_pblocks roi] -add "$::env(XRAY_ROI)"

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
#set_property BITSTREAM.GENERAL.PERFRAMECRC YES [current_design]

#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_IBUF]

#write_checkpoint -force synth.dcp

# Place everything
place_design
write_checkpoint -force placed.dcp

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

close $fp
close $fp_wires

puts "routing design"
route_design

write_checkpoint -force design.dcp
#set_property BITSTREAM.GENERAL.DEBUGBITSTREAM YES [current_design]
write_bitstream -force design.bit
