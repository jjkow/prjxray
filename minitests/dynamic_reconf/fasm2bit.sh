set -ex

fasm_in=$1
if [ -z "$fasm_in" ] ; then
    echo "need .fasm arg"
    exit
fi
design_json=$2
if [ -z "$design_json" ] ; then
    echo "need .json arg"
    exit
fi
bit_out=$3
if [ -z "$bit_out" ] ; then
    bit_out=$(echo $fasm_in |sed s/.fasm/.bit/)
    if [ "$bit_out" = "$fasm_in" ] ; then
        echo "Expected fasm file"
        exit 1
    fi
fi

echo "Partial FASM .fasm: $fasm_in"
echo "ROI Grid .json: $design_json"
echo "Partial .bit: $bit_out"

${XRAY_FASM2FRAMES} --sparse --roi $design_json $fasm_in roi_partial.frm

${XRAY_TOOLS_DIR}/xc7patch \
	--part_name ${XRAY_PART} \
	--part_file ${XRAY_PART_YAML} \
	--frm_file roi_partial.frm \
	--output_file $bit_out

