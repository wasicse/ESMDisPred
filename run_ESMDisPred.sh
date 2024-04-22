#! /bin/bash

#Model Selection

# model="ESMDisPred"
# model="ESM2DisPred"
# model="ESM2PDBDisPred"


dryRun=$1

# check if dryRun is set to 1 for docker image build
if [ "$dryRun" == "1" ]
then
    echo "Dry Run for Building Docker Image"
    model="ESM2PDBDisPred"
    rm -rf features
    rm -rf outputs
else
    echo "Running ESMDisPred"
    PS3='Please enter your choice: '
    options=("ESMDisPred" "ESM2DisPred" "ESM2PDBDisPred" "Quit")
    select opt in "${options[@]}"
    do
    case $opt in
        "ESMDisPred")
            echo "Running with DisPredict3.0 and ESM1 features"
            esmpOption="ESMDisPred"
            break
            ;;
        "ESM2DisPred")
            echo "Running with DisPredict3.0, ESM1 and ESM2 features"
            esmpOption="ESM2DisPred"
            break
            ;;      
        "ESM2PDBDisPred")
            echo "Running with DisPredict3.0, ESM1, ESM2 and structure related features"
            esmpOption="ESM2PDBDisPred"
            break
            ;;    
        "Quit")
            exit 0
            ;;
        *) echo "invalid option $REPLY";;
    esac
    done

    model=$esmpOption
fi





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

chmod -R 777 $fetures_dir

# # Run ESMDisPred
cd scripts
# Save Memory Usages
# $localpythonPath  systemResource.py --pid $$ --model $model &

# Run local Dispredict3.0 
./run_Dispredict3.sh $input_fasta ../$fetures_dir/Dispredict3.0 

# Run Dispredict3.0 Docker Container
# ./run_Dispredict3_Docker.sh $input_fasta ../$fetures_dir/Dispredict3.0 $n $localpythonPath

# Run ESM2
if [ "$model" == "ESM2DisPred" ]  || [ "$model" == "ESM2PDBDisPred" ] 
then
    mkdir -p $fetures_dir/ESM2
    $localpythonPath run_ESM2.py --fasta_filepath $input_fasta --output_path ../$fetures_dir/ESM2/
fi
# Run Predictions

$localpythonPath run_ESMDisPred.py  --fasta_filepath $input_fasta --output_path ../$output_dir_path --features_path ../$fetures_dir --model $model

cd -
# Current Directory 
# echo "Current Directory: $(pwd)"
# check if directory is owned by the user
if [ "$(stat -c "%U" "features/Dispredict3.0")" == "$USER" ]
then
    chmod -R 777 features/*
fi
if [ "$(stat -c "%U" "outputs/disorder")" == "$USER" ]
then

    chmod -R 777 outputs/*
fi
if [ "$dryRun" == "1" ]
then
    echo "Dry Run. Removing features and outputs directories"
    rm -rf features
    rm -rf outputs

fi