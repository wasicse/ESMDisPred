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
export TORCH_HOME=$(pwd)/largeModels
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
    models=("ESMDisPred-DNN")
    rm -rf features outputs

    n=1
    localpythonPath="../.venv/bin/python"
    _docker_py="/opt/.pyenv/versions/miniconda3-4.7.12/envs/py39/bin/python"
    _local_py="$(pwd)/.venv_py39/bin/python"
    if [ -f "$_docker_py" ]; then
        localpythonPath2="$_docker_py"
    elif [ -f "$_local_py" ]; then
        localpythonPath2="$_local_py"
    else
        echo "ERROR: conda py39 environment not found. Run ./install_dependencies.sh first."
        exit 1
    fi
    input_fasta="$(pwd)/example/sample.fasta"
    features_dir="features"
    output_dir_path="outputs/"

# ================================================================
# 2. Normal execution mode
# ================================================================
else
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: $0 <input_fasta> <output_dir> [model_option]"
        echo ""
        echo "Model options:"
        echo "  1 or ESMDisPred-1     - DisPredict3.0 + ESM1"
        echo "  2 or ESMDisPred-2     - DisPredict3.0 + ESM1 + ESM2"
        echo "  3 or ESMDisPred-2PDB  - DisPredict3.0 + ESM1 + ESM2 + PDB"
        echo "  4 or ESMDisPred-DNN   - CNN–Transformer hybrid"
        echo "  5 or all              - Run ALL models"
        echo ""
        echo "If model_option is not provided, you will be prompted interactively."
        exit 1
    fi

    input_fasta=$1
    output_dir_path=$2/
    model_choice=${3:-}  # Optional third parameter
    localpythonPath="../.venv/bin/python"
    _docker_py="/opt/.pyenv/versions/miniconda3-4.7.12/envs/py39/bin/python"
    _local_py="$(pwd)/.venv_py39/bin/python"
    if [ -f "$_docker_py" ]; then
        localpythonPath2="$_docker_py"
    elif [ -f "$_local_py" ]; then
        localpythonPath2="$_local_py"
    else
        echo "ERROR: conda py39 environment not found. Run ./install_dependencies.sh first."
        exit 1
    fi

    echo "Running ESMDisPred pipeline"
    echo "Input FASTA: $input_fasta"
    echo "Output Dir : $output_dir_path"

    # If model choice provided as parameter, use it
    if [ -n "$model_choice" ]; then
        choice="$model_choice"
        echo "Using model option from parameter: $choice"
    else
        # Interactive mode
        echo "Select model variant:"
        echo "1) ESMDisPred-1  (DisPredict3.0 + ESM1)"
        echo "2) ESMDisPred-2  (DisPredict3.0 + ESM1 + ESM2)"
        echo "3) ESMDisPred-2PDB  (DisPredict3.0 + ESM1 + ESM2 + PDB features)"
        echo "4) ESMDisPred-DNN  (CNN–Transformer hybrid)"
        echo "5) Run ALL models"
        echo "6) Quit"
        read -p "Enter choice [1-6]: " choice
    fi

    # Process the choice
    case $choice in
        1|ESMDisPred-1)
            echo "→ Running with DisPredict3.0 + ESM1 features"
            models=("ESMDisPred-1")
            ;;
        2|ESMDisPred-2)
            echo "→ Running with DisPredict3.0 + ESM1 + ESM2 features"
            models=("ESMDisPred-2")
            ;;
        3|ESMDisPred-2PDB)
            echo "→ Running with DisPredict3.0 + ESM1 + ESM2 + PDB structural information"
            models=("ESMDisPred-2PDB")
            ;;
        4|ESMDisPred-DNN)
            echo "→ Running with CNN–Transformer hybrid model"
            models=("ESMDisPred-DNN")
            ;;
        5|all|ALL)
            echo "→ Running ALL models"
            models=("ESMDisPred-1" "ESMDisPred-2" "ESMDisPred-2PDB" "ESMDisPred-DNN")
            ;;
        6|quit|QUIT)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option: $choice"
            echo "Valid options: 1, 2, 3, 4, 5, ESMDisPred-1, ESMDisPred-2, ESMDisPred-2PDB, ESMDisPred-DNN, all"
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
mkdir -p "$features_dir" "$output_dir_path" "$features_dir/Dispredict3.0" 2>/dev/null || true
# chmod -R 777 "$features_dir" 2>/dev/null || true
# chmod -R 777 "$output_dir_path" 2>/dev/null || true


# ================================================================
# 4. Setup logging (single file, append mode)
# ================================================================
LOG_FILE="$(realpath "$output_dir_path")/esmdispred.log"
touch "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}


echo "" >> "$LOG_FILE"
log "=========================================================="
log "NEW RUN STARTED"
log "=========================================================="
log "Input FASTA: $input_fasta"
log "Output Dir: $output_dir_path"
log "Features Dir: $features_dir"
log "Models to run: ${models[*]}" 

# ================================================================
# 5. Run feature extraction (once for all models)
# ================================================================
cd scripts

log "→ Extracting DisPredict3.0 features..."
./run_Dispredict3.sh "$input_fasta" "../$features_dir/Dispredict3.0" 2>&1 | tee -a "$LOG_FILE"

log "→ Generating ESM2 embeddings..."
mkdir -p ../"$features_dir"/ESM2
"$localpythonPath" run_ESM2.py \
    --fasta_filepath "$input_fasta" \
    --output_path ../"$features_dir"/ESM2/ 2>&1 | tee -a "$LOG_FILE"

# ================================================================
# 6. Run prediction for each model
# ================================================================
for model in "${models[@]}"; do
    log "================================================="
    log "→ Running $model prediction..."
    log "================================================="
    
    if [[ "$model" == "ESMDisPred-1" || "$model" == "ESMDisPred-2" || "$model" == "ESMDisPred-2PDB" ]]; then
        log "Running ESMDisPred..."
        "$localpythonPath" run_ESMDisPred.py \
            --fasta_filepath "$input_fasta" \
            --output_path ../"$output_dir_path" \
            --features_path ../"$features_dir" \
            --model "$model" 2>&1 | tee -a "$LOG_FILE"
    else
        log "Running ESMDisPred-DNN"
        "$localpythonPath2" transformer_Inference.py \
            --fasta_filepath "$input_fasta" \
            --features_path "../$features_dir" \
            --output_path "../$output_dir_path" \
            --model "$model" \
            --run_dir "../models" 2>&1 | tee -a "$LOG_FILE"
    fi
    
    log "→ $model completed."
done

cd - > /dev/null

# ================================================================
# 7. Cleanup and permissions
# ================================================================
# chmod -R 777 features 2>/dev/null || true
# chmod -R 777 outputs 2>/dev/null || true

if [ "$dryRun" == "1" ]; then
    log "[Dry Run Complete] Cleaning temporary directories..."
    rm -rf features outputs
fi

log "=========================================================="
log "RUN COMPLETED"
log "Models executed: ${models[*]}"
log "Results saved to: $output_dir_path"
log "=========================================================="
echo "ESMDisPred run completed. Check the log file at $LOG_FILE for details."