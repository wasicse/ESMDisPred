#!/bin/bash
# ================================================================
# ESMDisPred Launcher
# ------------------------------------------------
# Structure-Aware CNN–Transformer Framework for
# Intrinsically Disordered Protein (IDP) Prediction
# ================================================================

set -e  # exit on error

# ------------------------------------------------
# 0. Environment setup
# ------------------------------------------------
export TORCH_HOME=$(pwd)/.cache
export TORCH_HOME=/opt/ESMDisPred/largeModels
dryRun=$1

echo "================================================="
echo " ESMDisPred - Intrinsically Disordered Protein Prediction"
echo "================================================="

echo "→ Downloading large models..."
./run_downloadLargeModels.sh


# ================================================================
# 1. Dry run setup (used during Docker image build)
# ================================================================
if [ "$dryRun" == "1" ]; then
    echo "[Dry Run Mode] Setting up environment for Docker build..."
    model="ESM2PDBDisPred"
    rm -rf features outputs

    n=1
    localpythonPath="../.venv/bin/python"
    input_fasta="$(pwd)/example/sample.fasta"
    features_dir="features"
    output_dir_path="outputs/"

# ================================================================
# 2. Normal execution mode
# ================================================================
else
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: $0 <input_fasta> <output_dir>"
        exit 1
    fi

    input_fasta=$1
    output_dir_path=$2/
    localpythonPath="../.venv/bin/python"

    echo "Running ESMDisPred pipeline"
    echo "Input FASTA: $input_fasta"
    echo "Output Dir : $output_dir_path"

    echo "Select model variant:"
echo "1) ESMDisPred-1  (DisPredict3.0 + ESM1)"
echo "2) ESMDisPred-2  (DisPredict3.0 + ESM1 + ESM2)"
echo "3) ESMDisPred-2PDB  (DisPredict3.0 + ESM1 + ESM2 + PDB features)"
echo "4) ESMDisPred-DNN  (CNN–Transformer hybrid)"
echo "5) Quit"
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        echo "→ Running with DisPredict3.0 + ESM1 features"
        model="ESMDisPred"
        ;;
    2)
        echo "→ Running with DisPredict3.0 + ESM1 + ESM2 features"
        model="ESM2DisPred"
        ;;
    3)
        echo "→ Running with DisPredict3.0 + ESM1 + ESM2 + PDB structural features"
        model="ESM2PDBDisPred"
        ;;
    4)
        echo "→ Running with CNN–Transformer hybrid model (DisPredict3.0 + ESM1 + ESM2 + structure features)"
        model="ESMDisPredDNN"
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option. Please select a number between 1 and 5."
        exit 1
        ;;
esac

    n=1
    features_dir="features"
fi


# ================================================================
# 3. Prepare directories
# ================================================================
echo "→ Preparing directories..."
mkdir -p "$features_dir" "$output_dir_path" "$features_dir/Dispredict3.0"
chmod -R 777 "$features_dir"

# ================================================================
# 4. Run feature extraction
# ================================================================
cd scripts

echo "→ Extracting DisPredict3.0 features..."
./run_Dispredict3.sh "$input_fasta" "../$features_dir/Dispredict3.0"

# Optional: use Docker version instead of local
# ./run_Dispredict3_Docker.sh "$input_fasta" "../$features_dir/Dispredict3.0" $n "$localpythonPath"

# Run ESM2 if required by model
if [[ "$model" == "ESMDisPred" || "$model" == "ESM2PDBDisPred" || "$model" == "ESM2PDBDisPred" || "$model" == "ESMDisPredDNN" ]]; then
    echo "→ Generating ESM2 embeddings..."
    mkdir -p ../"$features_dir"/ESM2
    "$localpythonPath" run_ESM2.py \
        --fasta_filepath "$input_fasta" \
        --output_path ../"$features_dir"/ESM2/
fi

# ================================================================
# 5. Run prediction
# ================================================================
echo "→ Running $model prediction..."
if [[ "$model" == "ESMDisPred" || "$model" == "ESM2PDBDisPred" || "$model" == "ESM2PDBDisPred" ]]; then
            echo "Running ESMDispred..."
        "$localpythonPath" run_ESMDisPred.py \
            --fasta_filepath "$input_fasta" \
            --output_path ../"$output_dir_path" \
            --features_path ../"$features_dir" \
            --model "$model"
        else
            echo "Running ESMDispred-DNN"
            "$localpythonPath" transformer_Inference.py \
            --run-dir ../models \           
            --output predictions.csv
    fi

cd - > /dev/null

# ================================================================
# 6. Cleanup and permissions
# ================================================================
chmod -R 777 features outputs

if [ "$dryRun" == "1" ]; then
    echo "[Dry Run Complete] Cleaning temporary directories..."
    rm -rf features outputs
fi

echo "✅ ESMDisPred run complete!"
