# XC7A35TICSG324-1L
export XRAY_PART=xc7a35tcsg324-1
export XRAY_PINCFG=ARTY-A7-SWBUT
export XRAY_DIN_N_LARGE=0
export XRAY_DOUT_N_LARGE=3

# Used HCLK Tiles
# TODO: automatically detect HCLKs which will be used
export XRAY_ROI_HCLK="X98Y78 X102Y78"

# PITCH
export XRAY_PITCH=2

# Define ROI by global coords:
# Note that minimal reconfiguration cell is one major column
# So define always GLOB_ROI_Y with the height of major column
# otherwise overlapping static configuration can broke
# Available heights:
#   ROW0:     Y0=53 Y1=103
#   ROW1_TOP: Y0=1 Y1=51
#   ROW1_BOT: Y0=105 Y1=155
export GLOB_ROI_X1=97
export GLOB_ROI_X2=104
export GLOB_ROI_Y1=53
export GLOB_ROI_Y2=103

# Define ROI grid coords
export XRAY_ROI_GRID_X1=38
export XRAY_ROI_GRID_X2=41
export XRAY_ROI_GRID_Y1=75
export XRAY_ROI_GRID_Y2=99

# Used to draw Pblock (for other blocks see: settings/artix7.sh)
# These settings must remain in sync with artix7.sh
export XRAY_ROI="SLICE_X58Y75:SLICE_X65Y99"

# Heights of the major rows in CLB coords
export XRAY_MAJOR_ROWS="ROW0.50:99 ROW1_TOP.100:149 ROW1_BOT.0:49"

source $XRAY_DIR/utils/environment.sh
