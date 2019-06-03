# XC7A35TICSG324-1L
export XRAY_PART=xc7a35tcsg324-1
export XRAY_PINCFG=ARTY-A7-SWBUT
export XRAY_DIN_N_LARGE=0
export XRAY_DOUT_N_LARGE=3

# HCLK Tile
export XRAY_ROI_HCLK="CLK_HROW_TOP_R_X60Y130/CLK_HROW_CK_BUFHCLK_L0"

# PITCH
export XRAY_PITCH=2

# Define ROI by global coords
export GLOB_ROI_X1=62
export GLOB_ROI_X2=74
export GLOB_ROI_Y1=53
export GLOB_ROI_Y2=103

# Define ROI grid coords
export XRAY_ROI_GRID_X1=24
export XRAY_ROI_GRID_X2=29
export XRAY_ROI_GRID_Y1=50
export XRAY_ROI_GRID_Y2=99

# Used to draw Pblock (for other blocks see: settings/artix7.sh)
# These settings must remain in sync with artix7.sh
export XRAY_ROI="SLICE_X36Y50:SLICE_X47Y99"

source $XRAY_DIR/utils/environment.sh
