import xjson
import csv
import argparse
import sys
import fasm
from prjxray.db import Database
from prjxray.roi import Roi
from prjxray.util import get_db_root

def main():
    parser = argparse.ArgumentParser(
        description=
        "Creates design.json from output of ROI generation tcl script.")
    parser.add_argument('--design_info', required=True)
    parser.add_argument('--fasm', required=True)

    args = parser.parse_args()

    design_json = {}
    design_json['ports'] = []
    design_json['info'] = {}
    with open(args.design_info) as f:
        for l in f:
            name, value = l.strip().split(' = ')

            design_json['info'][name] = int(value)

    db = Database(get_db_root())
    grid = db.grid()

    roi = Roi(
        db=db,
        x1=design_json['info']['GRID_X_MIN'],
        y1=design_json['info']['GRID_Y_MIN'],
        x2=design_json['info']['GRID_X_MAX'],
        y2=design_json['info']['GRID_Y_MAX'],
    )

    xjson.pprint(sys.stdout, design_json)

if __name__ == '__main__':
    main()
