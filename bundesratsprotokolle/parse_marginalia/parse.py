"""
Generate jsons for indexing marginalia. I ran it like this:

1. unzip the metadata xml-export and change in the current folder
2. create folder `jsons`
3. inside the currend folder run
```bash
for i in $(ls -1 | egrep '^[[:digit:]]+'); do
    python parse.py $i > ./jsons/$i.json
done
```
"""

import xml.etree.ElementTree as ET
import json

from typing import Dict, Iterator
from sys import argv
from os import walk, listdir


def parse_page(dirpath: str, filename: str) -> Iterator[Dict[str, object]]:
    with open(f"{dirpath}/{filename}", "r") as f:
        xml_page_root = ET.fromstring(f.read())[1]

        for page in [p for p in xml_page_root
                     if p.get("custom") and 
                     "{type:marginalia;}" in p.get("custom")]:

            # the last tag contains the string we want
            marg_text = page[-1][0].text

            # if the string is empty, skip it
            if not marg_text:
                continue

            # filename format looks like VOLID_PAGENUM_PAGEID.xml
            _, page_num, __ = filename.split(".")[0].split("_")
            entry = {"page": int(page_num),
                     "text": marg_text.replace("\n", " ")}

            yield entry


def parse_volume(volume_dir_path: str) -> Dict[str, object]:

    assert len(listdir(volume_dir_path)) == 1

    vol = {
        "Name": listdir(volume_dir_path).pop(),
        "id": int(argv[1].strip("/")),
        "marginalia": []
    }

    # the page files are in the subfolders named "page"
    for dp, __, filenames in [(dp, dn, fn) for (dp, dn, fn) in walk(argv[1])
                              if dp.endswith("page")]:
        for filename in [fn for fn in filenames if fn.endswith(".xml")]:
            assert hasattr(vol["marginalia"], "append")

            for entry in parse_page(dp, filename):
                vol["marginalia"].append(entry)

    return vol


print(json.dumps(parse_volume(argv[1]), indent=4, ensure_ascii=False))
