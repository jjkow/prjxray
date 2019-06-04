import argparse
import sys
import os
import re

# TODO: checking if ROI is in more than one major row
def get_major_row(row_map, y_coord):
    res = ''
    for r in row_map:
        if y_coord in range(row_map[r][0], row_map[r][1] + 1):
            res = r
            break
    return res

def main():
    parser = argparse.ArgumentParser(
        description=
        "Creates partial.fasm from FASM with given Pblock boundaries.")
    parser.add_argument('--fasm', required=True)

    # ROI border in slice coords
    parser.add_argument('--ltile', required=True)
    parser.add_argument('--htile', required=True)

    args = parser.parse_args()

    gridx_min, gridy_min = args.ltile.split(",")
    gridx_max, gridy_max = args.htile.split(",")

    pfile = open("partial.fasm", "w+")

    # List all types of tiles we want to contain in ROI
    tiles = ['CLBLL', 'CLBLM', 'RAMB', 'DSP', 'INT']

    pblock_hclk = str(os.environ['XRAY_ROI_HCLK'])
    clk_coords = re.findall('X[0-9]+Y[0-9]+', pblock_hclk)

    # Major rows coordinates. Those are needed to
    # check if any static logic is in the same major
    # column with PR area. If it is we need to keep this
    # information and attach it to partial bit
    # This should be described as env variable in format:
    # 'ROW0.nn:nn ROW_TOP1.nn:nn ROW_BOT1.nn::nn ROW_TOP2.nn:nn etc.'
    major_rows = str(os.environ['XRAY_MAJOR_ROWS'])
    major_rows = major_rows.split(' ')
    row_map = {}
    for row in major_rows:
        row = row.split('.')
        # {'ROW' : [y_min, y_max]}
        row[1] = re.findall('\d+', row[1])
        row[1] = map(int, row[1])
        row[1] = list(row[1])
        row_map[row[0]] = row[1]

    # Find out in which major row ROI is declared
    roi_major_row = get_major_row(row_map, int(gridy_min))
    roi_major_row2 = get_major_row(row_map, int(gridy_max))
    if roi_major_row != roi_major_row2:
        print('Unsupported pblock! ROI cannot be in more than one clock domain!')
        return 1

    change_roi = False

    with open(args.fasm) as f:
        for l in f:
            fasm_in_roi = False
            found_tile = False
            overlap = False
            # Check major row
            for t in tiles:
                if t in l:
                    found_tile = True
                    break

            if found_tile:
                which_row = get_major_row(row_map, int(re.findall('X[0-9]+Y[0-9]+', l)[0].split('Y')[1]))

                # Check for tiles in grid coords
                for x in range(int(gridx_min), int(gridx_max) + 1):
                    # Check if potentially the tile is in the same column as ROI
                    s = 'X' + str(x)
                    if s in l:
                        if which_row == roi_major_row:
                            overlap = True
                            change_roi = True
                    for y in range(int(gridy_min), int(gridy_max) + 1):
                        # Check for row coord
                        coords = s + 'Y' + str(y)
                        if coords in l:
                            # We have a hit, the tile is in ROI
                            fasm_in_roi = True
                            break
                    if fasm_in_roi or overlap:
                        pfile.write(l)
                        break
            else:
                if 'HCLK' in l:
                    for hclk in clk_coords:
                        if hclk in l:
                            pfile.write(l)

    pfile.close()

    #if change_roi:
    #    dfile = open(args.design_info, "r")
    #    with open("design_info_ext.txt", "w") as f:
    #        for l in dfile:
    #            line = l
    #            if 'GRID_Y_MAX' in l:
    #                line = 'GRID_Y_MAX = ' + str(row_map[roi_major_row][1])
    #            f.write(line)
    #    dfile.close()
    #    os.rename("design_info_ext.txt", args.design_info)


if __name__ == '__main__':
    main()

