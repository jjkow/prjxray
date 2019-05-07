#!/usr/bin/env bash

# This script requires an XC7A50T family part

set -ex

if [ $1 == "BLACKBOX" ]; then
    export XRAY_ROIV="../blackbox.v"
elif [ $1 == "TEST1" ]; then
    export XRAY_ROIV="../test1.v"
elif [ $1 == "TEST2" ]; then
    export XRAY_ROIV="../test2.v"
else
    echo "Please specify as argument: BLACKBOX, TEST1, TEST2"
    exit 1
fi

source ${XRAY_DIR}/utils/environment.sh

export XRAY_PINCFG=${XRAY_PINCFG:-ARTY-A7-SWBUT}
export BUILD_DIR=${BUILD_DIR:-build}

export ROI_MIN_X=36
export ROI_MIN_Y=50
export ROI_MAX_X=65
export ROI_MAX_Y=99

export GLOB_ROI_MIN_X=62
export GLOB_ROI_MIN_Y=53
export GLOB_ROI_MAX_X=104
export GLOB_ROI_MAX_Y=103

export PITCH=${XRAY_PITCH:-2}
export DIN_N=${XRAY_DIN_N_LARGE:-0}
export DOUT_N=${XRAY_DOUT_N_LARGE:-3}
export XRAY_ROI=${XRAY_ROI_LARGE:-SLICE_X${ROI_MIN_X}Y${ROI_MIN_Y}:SLICE_X${ROI_MAX_X}Y${ROI_MAX_Y}}

echo ${DIN_N}
echo ${DOUT_N}
echo ${XRAY_ROI}

mkdir -p $BUILD_DIR
pushd $BUILD_DIR

${XRAY_VIVADO} -mode batch -source ../runme.tcl
test -z "$(fgrep CRITICAL vivado.log)"

${XRAY_BITREAD} -F $XRAY_ROI_FRAMES -o design.bits -z -y design.bit
python3 ${XRAY_DIR}/utils/bit2fasm.py --verbose design.bit > design.fasm
python3 ${XRAY_DIR}/utils/fasm2frames.py design.fasm design.frm
PYTHONPATH=$PYTHONPATH:$XRAY_DIR/utils python3 ../create_design_json.py \
    --design_info_txt design_info.txt \
    --design_txt design.txt \
    --pad_wires design_pad_wires.txt \
    --design_fasm design.fasm > design.json

python3 ../extract_roi.py --fasm design.fasm --ltile ${ROI_MIN_X},${ROI_MIN_Y} \
    --htile ${ROI_MAX_X},${ROI_MAX_Y} \
    --ledge ${GLOB_ROI_MIN_X},${GLOB_ROI_MIN_Y} \
    --hedge ${GLOB_ROI_MAX_X},${GLOB_ROI_MAX_Y}

# Hack to get around weird clock error related to clk net not found
# Remove following lines:
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_IBUF]
#set_property FIXED_ROUTE { { CLK_BUFG_BUFGCTRL0_O CLK_BUFG_CK_GCLK0 ... CLK_L1 CLBLM_M_CLK }  } [get_nets clk_net]
#if [ -f fixed.xdc ] ; then
#    cat fixed.xdc |fgrep -v 'CLOCK_DEDICATED_ROUTE FALSE' |fgrep -v 'set_property FIXED_ROUTE { { CLK_BUFG_BUFGCTRL0_O' >fixed_noclk.xdc
#fi
#popd
