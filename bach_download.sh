#!/bin/bash

file="results/HCT116_ChIP_Raw_Data_URLs.csv"

while read line
do
  outfile=$(echo $line | awk 'BEGIN { FS = "/" }; {print $NF}')
  curl -o "HCT116_ChIP_Raw_Data/$outfile" -L "$line"
done < "$file"
