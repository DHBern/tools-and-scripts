import os
import json
import pprint

from sys import argv, stderr, exit as sys_exit
from typing import Dict, List


def print_usage():
    msg = f"Usage: {argv[0]} /path/to/public/staticDirectory/"\
           "staticDirectory.json /path/to/marginalia_json/folder"
    print(msg)


def main():
    stat_dir_json_path = argv[1]
    marginalia_folder_path = argv[2]

    with open(stat_dir_json_path, "r") as stat_dir_json:
        vol_directory = json.loads(stat_dir_json.read())

    years = {vol["year"]: [v["docId"] for v in vol_directory
                           if v["year"] == vol["year"]]
             for vol in vol_directory}

    for year, vols in years.items():
        volumes = []
        for vol_id in vols:
            with open(f"{marginalia_folder_path}/{vol_id}.json", "r")\
                 as marginalia:
                volumes.append(json.loads(marginalia.read()))

        out_file_path = f"./{year}.json"
        if os.path.exists(out_file_path):
            print(f"I won't overwrite {out_file_path}, exiting...",
                  file=stderr)
            sys_exit(1)

        with open(out_file_path, "w+") as out_file:
            out_file.write(json.dumps(volumes, indent=4, ensure_ascii=False))


if __name__ == "__main__":
    if len(argv) != 3 or not (os.path.exists(argv[1]) and
                              os.path.exists(argv[2])):
        print_usage()
        sys_exit(1)

    main()
