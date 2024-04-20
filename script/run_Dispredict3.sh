#! /bin/bash

# Input arguments
input_fasta=$1
output_dir=$2

echo "Input fasta file: $input_fasta"
echo "Output directory: $output_dir"

# print current directory
echo "Current directory: $(pwd)"
mkdir -p $output_dir/predictions
mkdir -p $output_dir/features

cd ../tools/Dispredict3.0/script
cp tcsh /tmp/
source ../.venv/bin/activate
../.venv/bin/python Dispredict3.0.py -f $input_fasta -o ../../$output_dir
rm -rf ../tools/fldpnn/pyflDPnn_tmp*/
rm -rf ../tools/fldpnn/output/*
mkdir -p ../../../outputs/disorder
mkdir -p ../../../outputs/disorder/Dispredict3.0
cp ../../$output_dir/predictions/* ../../../outputs/disorder/Dispredict3.0/
cd -