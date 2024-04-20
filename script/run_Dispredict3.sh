#! /bin/bash
# Number of parallel run



start=`date +%s%N` 
# Input arguments
input_fasta=$1
output_dir=$2
n=$3
localpythonPath=$4

echo "Input fasta file: $input_fasta"

cd ../tools/Dispredict3.0
./install_dependencies.sh
cd script
../.venv/bin/poetry run python Dispredict3.0.py -f "../example/sample.fasta" -o "../output/"