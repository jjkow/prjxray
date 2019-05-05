#!/usr/bin/env bash

# This script requires an XC7A50T family part

set -ex

source ${XRAY_DIR}/utils/environment.sh
source zybo.sh

export BUILD_DIR=${BUILD_DIR:-build}

stat ${XRAY_DIR}/database/${XRAY_DATABASE}/${XRAY_PART}.yaml >/dev/null

echo "Design:"
export PITCH=${XRAY_PITCH:-3}
export DIN_N=${XRAY_DIN_N_LARGE:-3}
export DOUT_N=${XRAY_DOUT_N_LARGE:-3}
export XRAY_ROI=${XRAY_ROI_LARGE:-SLICE_X22Y50:SLICE_X43Y99}

echo ${DIN_N}
echo ${DOUT_N}
echo ${XRAY_ROI}
echo ${WITH_ZYNQ}

if [ $1 = "UTILS=0" ]; then
    mkdir -p $BUILD_DIR
    pushd $BUILD_DIR

    ${XRAY_VIVADO} -mode batch -source ../runme.tcl
    #test -z "$(fgrep CRITICAL vivado.log)"
    if [ "$WITH_BOOTGEN" = 1 ]; then
        bootgen -image system.bif -w -o design.bit.bin
    fi
elif [ $1 = "UTILS=1" ]; then
    ${XRAY_BITREAD} -o design.bits -y build/design.bit
    #${XRAY_SEGPRINT} design.bits -zd > design.segp
    python3 ${XRAY_DIR}/utils/bit2fasm.py build/design.bit > design.fasm
    python3 ${XRAY_DIR}/utils/fasm2frames.py design.fasm design.frm
    #PYTHONPATH=$PYTHONPATH:$XRAY_DIR/utils python3 create_design_json.py \
    #    --design_info_txt build/design_info.txt \
    #    --design_txt build/design.txt \
    #    --pad_wires build/design_pad_wires.txt \
    #    --design_fasm design.fasm > design.json

    bash fasm2bit.sh partial.fasm blackbox.bit fixed.bit
    bootgen -image system.bif -w -o design.bit.bin
else
    echo "Set UTILS=<value>!"
fi

