import argparse
import sys

def main():
    parser = argparse.ArgumentParser(
        description=
        "Creates partial.fasm from design.fasm with given ROI boundaries.")
    parser.add_argument('--design_fasm', required=True)
    parser.add_argument('--x_min', required=True)
    parser.add_argument('--x_max', required=True)
    parser.add_argument('--y_min', required=True)
    parser.add_argument('--y_max', required=True)

    args = parser.parse_args()

    pfile = open("partial.fasm", "w+")

    with open(args.design_fasm) as f:
        for l in f:
            for i in range(int(args.x_min), int(args.x_max) + 1):
                for j in range(int(args.y_min), int(args.y_max) + 1):
                    s = 'X' + str(i) + 'Y' + str(j)
                    if s in l:
                        pfile.write(l)
                        break
                if s in l:
                    break

    pfile.close()

if __name__ == '__main__':
    main()

