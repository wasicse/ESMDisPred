#! /bin/bash
#Model Selection

# model="ESMDispred"
# model="ESM2Dispred"
model="ESM2PDBDispred"

# read n
# Parallel run for Dispredict3.0 using multiple Docker containers.The parallel run should be less than the number of protein sequcnecs in input fasta file."
n=1
# local python path
localpythonPath="../.venv/bin/python"
# input fasta file
input_fasta="$(pwd)/example/sample.fasta"
# output directory for features
fetures_dir="features"
# output directory for predictions
output_dir_path="outputs/"

# Create output directories
mkdir -p $fetures_dir
mkdir -p $output_dir_path
mkdir -p $fetures_dir/Dispredict3.0 
mkdir -p $fetures_dir/ESM2
chmod -R 777 $fetures_dir

# # Run ESMDisPred
cd script
# Save Memory Usages
$localpythonPath  systemResource.py --pid $$ &
# # Run Dispredict3.0
./run_Dispredict3.sh $input_fasta ../$fetures_dir/Dispredict3.0 $n $localpythonPath
# # Run ESM2

tempmodel=$model
if [ "$model" == "ESM2Dispred" ]  || [ "$model" == "ESM2PDBDispred" ] 
then
    $localpythonPath run_ESM2.py --fasta_filepath $input_fasta --output_path ../$fetures_dir/ESM2/
fi
# # Run Predictions

$localpythonPath run_ESMDisPred.py  --fasta_filepath $input_fasta --output_path ../$output_dir_path --features_path ../$fetures_dir --model $tempmodel


