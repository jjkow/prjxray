# Number of package inputs going to ROI
set DIN_N 8
if { [info exists ::env(DIN_N) ] } {
    set DIN_N "$::env(DIN_N)"
}
# Number of ROI outputs going to package
set DOUT_N 8
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
set XRAY_ROI_X0 [lindex [split [lindex [split "$::env(XRAY_ROI)" Y] 0] X] 1]
set XRAY_ROI_X1 [lindex [split [lindex [split "$::env(XRAY_ROI)" X] 2] Y] 0]
set XRAY_ROI_Y0 [lindex [split [lindex [split "$::env(XRAY_ROI)" Y] 1] :] 0]
set XRAY_ROI_Y1 [lindex [split "$::env(XRAY_ROI)" Y] 2]

set X_BASE $XRAY_ROI_X0
set Y_BASE $XRAY_ROI_Y0

set Y_CLK_BASE $Y_BASE
set Y_DIN_BASE [expr "$Y_CLK_BASE + $PITCH"]
set Y_DOUT_BASE [expr "$XRAY_ROI_Y1 - $DOUT_N * $PITCH"]

# Y_OFFSET: offset amount to shift the components on the y column to avoid hard blocks
set Y_OFFSET 24

set part "$::env(XRAY_PART)"
set pincfg ""
if { [info exists ::env(XRAY_PINCFG) ] } {
    set pincfg "$::env(XRAY_PINCFG)"
}
set roiv "../blackbox.v"
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

source ../../../utils/utils.tcl

create_project -force -part $::env(XRAY_PART) design design
read_verilog ../roi.v
read_verilog $roiv
set fixed_xdc ""
if { [info exists ::env(XRAY_FIXED_XDC) ] } {
    set fixed_xdc "$::env(XRAY_FIXED_XDC)"
}

synth_design -top roi -flatten_hierarchy none -verilog_define DIN_N=$DIN_N -verilog_define DOUT_N=$DOUT_N

if {$fixed_xdc ne ""} {
    read_xdc $fixed_xdc
}

# Map of top level net names to IOB pin names
array set net2pin [list]

# Create pin assignments based on what we are targetting
# A50T I/O Bank 16 sequential layout
if {$part eq "xc7a50tfgg484-1"} {
    # Partial list, expand as needed
    set bank_16 "F21 G22 G21 D21 E21 D22 E22 A21 B21 B22 C22 C20 D20 F20 F19 A19 A18"
    set banki 0

    # CLK
    set pin [lindex $bank_16 $banki]
    incr banki
    set net2pin(clk) $pin

    # DIN
    for {set i 0} {$i < $DIN_N} {incr i} {
        set pin [lindex $bank_16 $banki]
        incr banki
        set net2pin(din[$i]) $pin
    }

    # DOUT
    for {set i 0} {$i < $DOUT_N} {incr i} {
        set pin [lindex $bank_16 $banki]
        incr banki
        set net2pin(dout[$i]) $pin
    }
} elseif {$part eq "xc7a35tcsg324-1"} {
    # Arty A7 switch, button, and LED
    if {$pincfg eq "ARTY-A7-SWBUT"} {
        # https://reference.digilentinc.com/reference/programmable-logic/arty/reference-manual?redirect=1
        # 4 switches then 4 buttons
        set sw_but "A8 C11 C10 A10  D9 C9 B9 B8"
        # 4 LEDs then 4 RGB LEDs (green only)
        set leds "J4 J2 H6"
        set blinky "T10"

        # 100 MHz CLK onboard
        set pin "E3"
        set net2pin(clk) $pin

        # Static LED
        set net2pin(blinky) $blinky

        # DIN
        for {set i 0} {$i < $DIN_N} {incr i} {
            set pin [lindex $sw_but $i]
            set net2pin(din[$i]) $pin
        }

        # DOUT
        for {set i 0} {$i < $DOUT_N} {incr i} {
            set pin [lindex $leds $i]
            set net2pin(dout[$i]) $pin
        }

        # Arty A7 pmod
        # Disabled per above
    } elseif {$pincfg eq "ARTY-A7-PMOD"} {
        # https://reference.digilentinc.com/reference/programmable-logic/arty/reference-manual?redirect=1
        set pmod_ja "G13 B11 A11 D12  D13 B18 A18 K16"
        set pmod_jb "E15 E16 D15 C15  J17 J18 K15 J15"
        set pmod_jc "U12 V12 V10 V11  U14 V14 T13 U13"

        # CLK on Pmod JA
        set pin [lindex $pmod_ja 0]
        set net2pin(clk) $pin

        # DIN on Pmod JB
        for {set i 0} {$i < $DIN_N} {incr i} {
            set pin [lindex $pmod_jb $i]
            set net2pin(din[$i]) $pin
        }

        # DOUT on Pmod JC
        for {set i 0} {$i < $DOUT_N} {incr i} {
            set pin [lindex $pmod_jc $i]
            set net2pin(dout[$i]) $pin
        }
    } else {
        error "Unsupported config $pincfg"
    }
} elseif {$part eq "xc7a35tcpg236-1"} {
    if {$pincfg eq "BASYS3-SWBUT"} {
        # https://raw.githubusercontent.com/Digilent/digilent-xdc/master/Basys-3-Master.xdc

        # Slide switches
        set ins "V17 V16 W16 W17 W15 V15 W14 W13 V2 T3 T2 R3 W2 U1 T1 R2"
        set outs "U16 E19 U19 V19 W18 U15 U14 V14 V13 V3 W3 U3 P3 N3 P1 L1"

        # UART
        lappend ins B18
        lappend outs A18


        # 100 MHz CLK onboard
        set pin "W5"
        set net2pin(clk) $pin

        # DIN
        for {set i 0} {$i < $DIN_N} {incr i} {
            set pin [lindex $ins $i]
            set net2pin(din[$i]) $pin
        }

        # DOUT
        for {set i 0} {$i < $DOUT_N} {incr i} {
            set pin [lindex $outs $i]
            set net2pin(dout[$i]) $pin
        }
    } else {
        error "Unsupported config $pincfg"
    }
} elseif {$part eq "xc7z010clg400-1"} {
    if {$pincfg eq "ZYBOZ7-SWBUT"} {
        # https://github.com/Digilent/digilent-xdc/blob/master/Zybo-Z7-Master.xdc

        # Slide switches and buttons
        set ins "G15 P15 W13 T16"
        set outs "M14 M15 G14 D18"

        # 125 MHz CLK onboard
        set pin "K17"
        set net2pin(clk) $pin

        # DIN
        for {set i 0} {$i < $DIN_N} {incr i} {
            set pin [lindex $ins $i]
            set net2pin(din[$i]) $pin
        }

        # DOUT
        for {set i 0} {$i < $DOUT_N} {incr i} {
            set pin [lindex $outs $i]
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

if {$fixed_xdc eq ""} {
    create_pblock roi
    set_property EXCLUDE_PLACEMENT 1 [get_pblocks roi]
    set_property CONTAIN_ROUTING true [get_pblocks roi]
    set_property DONT_TOUCH true [get_cells test]
    add_cells_to_pblock [get_pblocks roi] [get_cells test]
    resize_pblock [get_pblocks roi] -add "$::env(XRAY_ROI)"

    set_property CFGBVS VCCO [current_design]
    set_property CONFIG_VOLTAGE 3.3 [current_design]
    set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_IBUF]

    #write_checkpoint -force synth.dcp
}


proc loc_roi_clk_left {ff_x ff_y} {
    set slice_ff "SLICE_X${ff_x}Y${ff_y}"

    set cell [get_cells "test/clk_reg_reg"]
    set_property LOC $slice_ff $cell
    set_property BEL AFF $cell
}

proc loc_lut_in {index lut_x lut_y} {
    set slice_lut "SLICE_X${lut_x}Y${lut_y}"

    set cell [get_cells "test/ins[$index].lut"]
    set_property LOC $slice_lut $cell
    set_property BEL A6LUT $cell
}

proc loc_lut_out {index lut_x lut_y} {
    set slice_lut "SLICE_X${lut_x}Y${lut_y}"

    set cell [get_cells "test/outs[$index].lut"]
    set_property LOC $slice_lut $cell
    set_property BEL A6LUT $cell
}

proc net_bank_left {net} {
    set bank [get_property IOBANK [get_ports $net]]
    set left_banks "14 15 16"
    set right_banks "34 35"

    if {[lsearch -exact $left_banks $bank] >= 0} {
        return 1
    } elseif {[lsearch -exact $right_banks $bank] >= 0} {
        return 0
    } else {
        error "Bad bank $bank"
    }
}

# Manual placement
if {$fixed_xdc eq ""} {
    set x $X_BASE

    puts "Placing ROI clock"
    loc_roi_clk_left $x $Y_CLK_BASE

    # Place ROI inputs
    puts "Placing ROI inputs"
    set y_left $Y_DIN_BASE
    set y_right [expr {$Y_DIN_BASE + $Y_OFFSET}]
    for {set i 0} {$i < $DIN_N} {incr i} {
        if {[net_bank_left "din[$i]"]} {
            loc_lut_in $i $XRAY_ROI_X0 $y_left
            set y_left [expr {$y_left + $PITCH}]
        } else {
            loc_lut_in $i $XRAY_ROI_X1 $y_right
            set y_right [expr {$y_right + $PITCH}]
        }
    }

    # Place ROI outputs
    set y_left $Y_DOUT_BASE
    set y_right $Y_DOUT_BASE
    puts "Placing ROI outputs"
    for {set i 0} {$i < $DOUT_N} {incr i} {
        if {[net_bank_left "dout[$i]"]} {
            loc_lut_out $i $XRAY_ROI_X0 $y_left
            set y_left [expr {$y_left + $PITCH}]
        } else {
            loc_lut_out $i $XRAY_ROI_X1 $y_right
            set y_right [expr {$y_right + $PITCH}]
        }
    }
}

opt_design
place_design
write_checkpoint -force placed.dcp

puts "routing design"
route_design
write_checkpoint -force design.dcp
write_bitstream -force design.bit
