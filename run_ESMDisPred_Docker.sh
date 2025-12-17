#!/bin/bash
set -e

input_fasta=$1
output_dir=$2
model_option=${3:-}  # Optional 3rd parameter for model selection

if [ -z "$input_fasta" ] || [ -z "$output_dir" ]; then
    echo "Usage: $0 <input_fasta> <output_dir> [model_option]"
    echo ""
    echo "Example (interactive):"
    echo "  $0 \$(pwd)/example/sample.fasta outputs"
    echo ""
    echo "Example (non-interactive):"
    echo "  $0 \$(pwd)/example/sample.fasta outputs 3"
    echo "  $0 \$(pwd)/example/sample.fasta outputs ESMDisPred-2PDB"
    echo "  $0 \$(pwd)/example/sample.fasta outputs all"
    echo ""
    echo "Model options:"
    echo "  1 or ESMDisPred-1     - DisPredict3.0 + ESM1"
    echo "  2 or ESMDisPred-2     - DisPredict3.0 + ESM1 + ESM2"
    echo "  3 or ESMDisPred-2PDB  - DisPredict3.0 + ESM1 + ESM2 + PDB"
    echo "  4 or ESMDisPred-DNN   - CNN–Transformer hybrid"
    echo "  5 or all              - Run ALL models"
    exit 1
fi

echo "Input fasta file: $input_fasta"
echo "Output directory: $output_dir"
if [ -n "$model_option" ]; then
    echo "Model option: $model_option"
else
    echo "Model option: Interactive (will prompt)"
fi

# Create necessary directories
mkdir -p "$output_dir" features largeModels

ESMpath="/opt/ESMDisPred"

# Get the filename from input path
fasta_filename=$(basename "$input_fasta")

# Handle both relative and absolute paths for output_dir
if [[ "$output_dir" = /* ]]; then
    # Absolute path - use as is
    output_dir_abs="$output_dir"
else
    # Relative path - prepend $(pwd)
    output_dir_abs="$(pwd)/$output_dir"
fi

docker run -it \
  --user $(id -u):$(id -g) \
  -e HOME=/opt/ESMDisPred \
  -e XDG_CACHE_HOME=/opt/ESMDisPred/.cache \
  -e TORCH_HOME=/opt/ESMDisPred/largeModels \
  -v "$input_fasta":"$ESMpath/example/$fasta_filename" \
  -v "$output_dir_abs":"$ESMpath/outputs":rw \
  -v "$(pwd)/features":"$ESMpath/features":rw \
  -v "$(pwd)/largeModels":"$ESMpath/largeModels":rw \
  -v "$(pwd)/run_ESMDisPred.sh":"$ESMpath/run_ESMDisPred.sh" \
  -v "$(pwd)/scripts/transformer_Inference.py":"$ESMpath/scripts/transformer_Inference.py" \
  -v "$(pwd)/scripts/preprocess.py":"$ESMpath/scripts/preprocess.py" \
  -v "$(pwd)/models":"$ESMpath/models" \
  -v "$(pwd)/requirements.txt":"$ESMpath/requirements.txt" \
  -v "$(pwd)/run_downloadLargeModels.sh":"$ESMpath/run_downloadLargeModels.sh" \
  wasicse/esmdispred:version2 \
  ./run_ESMDisPred.sh "$ESMpath/example/$fasta_filename" outputs "$model_option"