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

# Define ROI by global coords
export GLOB_ROI_X1=62
export GLOB_ROI_X2=74
export GLOB_ROI_Y1=53
export GLOB_ROI_Y2=103

# Define ROI by CLBLL coords
export MAJOR_ROI_X1=24
export MAJOR_ROI_X2=29
export MAJOR_ROI_Y1=50
export MAJOR_ROI_Y2=99

# Used to draw Pblock (for other blocks see: settings/artix7.sh)
# These settings must remain in sync with artix7.sh
export XRAY_ROI="SLICE_X36Y50:SLICE_X47Y99"

export PITCH=${XRAY_PITCH:-2}
export DIN_N=${XRAY_DIN_N_LARGE:-0}
export DOUT_N=${XRAY_DOUT_N_LARGE:-3}

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

if [ $1 != "BLACKBOX" ]; then
python3 ../extract_roi.py --fasm design.fasm --ltile ${MAJOR_ROI_X1},${MAJOR_ROI_Y1} \
    --htile ${MAJOR_ROI_X2},${MAJOR_ROI_Y2} \
    --ledge ${GLOB_ROI_X1},${GLOB_ROI_Y1} \
    --hedge ${GLOB_ROI_X2},${GLOB_ROI_Y2}

    bash ../fasm2bit.sh partial.fasm fixed.bit
fi

# TODO:
#else
#    bash ../fasm2bit.sh partial.fasm blanking.bit
#fi
