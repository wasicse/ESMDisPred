#! /bin/bash

# Input arguments
input_fasta=$1
output_dir=$2

echo "Input fasta file: $input_fasta"

cd ../tools/Dispredict3.0/script
cp tcsh /tmp/
source ../.venv/bin/activate
../.venv/bin/python Dispredict3.0.py -f $1 -o $2
rm -rf ../tools/fldpnn/pyflDPnn_tmp*/
rm -rf ../tools/fldpnn/output/*
cd -