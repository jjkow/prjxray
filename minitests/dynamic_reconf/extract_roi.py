import argparse
import sys

def main():
    parser = argparse.ArgumentParser(
        description=
        "Creates partial.fasm from design.fasm with given ROI boundaries.")
    parser.add_argument('--fasm', required=True)

    # ROI border in slice coords
    parser.add_argument('--ltile', required=True)
    parser.add_argument('--htile', required=True)

    # ROI border in absolute cols/rows coords
    parser.add_argument('--ledge', required=True)
    parser.add_argument('--hedge', required=True)

    args = parser.parse_args()

    majorx_min, majory_min = args.ltile.split(",")
    majorx_max, majory_max = args.htile.split(",")
    col_min, row_min = args.ledge.split(",")
    col_max, row_max = args.hedge.split(",")

    pfile = open("partial.fasm", "w+")

    # List all types of tiles we want to contain in ROI
    tiles = ['CLBLL', 'CLBLM', 'RAMB', 'DSP', 'INT']
    clks = ['HCLK', 'BUFG', 'HROW']

    with open(args.fasm) as f:
        for l in f:
            fasm_in_roi = False
            found_tile = False

            # First check for tiles in major coords
            for x in range(int(majorx_min), int(majorx_max) + 1):
                for t in tiles:
                    if t in l:
                        found_tile = True
                        break
                if not found_tile:
                    # Invalid type, we need to check for CLK related
                    break
                for y in range(int(majory_min), int(majory_max) + 1):
                    # We have a line with known type - check for coords
                    s = 'X' + str(x) + 'Y' + str(y)
                    if s in l:
                        # If we have a hit, break from loops and fetch a new line
                        fasm_in_roi = True
                        pfile.write(l)
                        break
                if fasm_in_roi:
                    break

            if not fasm_in_roi:
                for c in clks:
                    if c in l:
                        for x in range(int(col_min), int(col_max) + 1):
                            for y in range(int(row_min), int(row_max) + 1):
                                s = 'X' + str(x) + 'Y' + str(y)
                                if s in l:
                                    pfile.write(l)
                                    break

    pfile.close()

if __name__ == '__main__':
    main()

