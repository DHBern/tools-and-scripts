#!/bin/bash
# NOTE : Process generated text files and decode QP encoding (quoted printable) 
# Dependent on qprint (sudo apt install qprint / brew install qprint)
FILES="*.txt"
for f in $FILES
do
  # echo "Processing $f file..."
  # run the qprint decoding on a copy of the file, then discard it
  mv "$f" "$f-tmp";
  cat "$f-tmp" | qprint -d > "$f";
  rm "$f-tmp"
done
