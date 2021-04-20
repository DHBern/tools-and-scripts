# -*- coding: utf-8 -*-

import pandas as pd
import os
import re
import argparse
import shutil

def main():
    # handle args
    parser = argparse.ArgumentParser(description="Train a language model with FLAIR.")
    parser.add_argument("folder", type=str, nargs='?', default='./',
                        help="path to folder containing txt files to rename and tif files to check")
    parser.add_argument("excelfile", type=str,
                        help="path to excelfile containing metadata")
    args = parser.parse_args()
    WORKSPACE = os.path.normpath(args.folder)
    EXCELFILE = os.path.normpath(args.excelfile)
    if not os.path.exists(WORKSPACE):
        raise ValueError("Folder " + WORKSPACE + " does not exist.")
    elif not os.path.exists(EXCELFILE):
        raise ValueError("Excelfile " + EXCELFILE + " does not exist.")
    else:
        txtfiles = get_filenames(WORKSPACE, "txt")
        bilder = get_filenames(WORKSPACE, "tif")
        data = get_data(EXCELFILE)
        rename_files(WORKSPACE, txtfiles, data)
        neuetxtfiles = get_filenames(WORKSPACE, "txt")
        log_missing_txt(WORKSPACE, bilder, neuetxtfiles)
        
# Aus der Ordnerstruktur in path alle Filenames mit der Endung .ending holen. 
def get_filenames(path, ending):
    txtfiles = []
    index = -1*len(ending)
    for root, _, files in os.walk(path, topdown=False):
        for name in files:
            if (os.path.join(root, name)[index:] == ending):
                p = os.path.join(root, name)
                txtfiles.append(p)
    return txtfiles

def get_data(excelfile):
    konkordanz = pd.read_excel(excelfile, sheet_name=0, names=["Signatur", "TransaktionsID"], usecols=[0,2], engine='openpyxl')
    return konkordanz

def rename_files(workspace, filenames, metadata):
    r = re.compile(r'(.*\_\d{5}\_.*)')
    to_rename = list(filter(r.match, filenames))
    for t in to_rename:
        print("Neu zu benennende Datei:", t)
        transaktionsid = re.findall(r'(\d{5})', t)
        signatur = metadata.loc[metadata.TransaktionsID == int(transaktionsid[0])].Signatur.values.tolist()
        for s in signatur:
            newname = re.sub(r'[^A-Za-z0-9]', "_", s) + ".txt"
            print("Neuer Name", newname)
            shutil.copy2(t, os.path.join(workspace, newname)) # Copy2 um die Metadaten des Files zu erhalten
        os.remove(t)
    print(len(to_rename), "Dateien wurden umbenannt oder aufgrund mehreren Signaturen kopiert.")

def log_missing_txt(workspace, bilderfilenames, txtfilenames):
    log = []
    for b in bilderfilenames:
        match = [s for s in txtfilenames if b[:-4] in s]
        if len(match) == 0:
            log.append(b)
    if len(log) > 0:
        with open(os.path.join(workspace, 'log.txt'), 'w') as F:
            F.write("Für folgende Bilddateien ist kein Txt-File vorhanden:\n")
            F.write("\n".join([str(x) for x in log]))
        print("Für Bilddateien ohne passende Textdatei, siehe log.txt")
    else:
        print("Für alle Bilddateien wurden passende Textdateien gefunden.")

if __name__ == "__main__":
	main()