#!/bin/bash
set -e

input_fasta=$1
output_dir=$2

if [ -z "$input_fasta" ] || [ -z "$output_dir" ]; then
    echo "Usage: $0 <input_fasta> <output_dir>"
    echo "Example: $0 \$(pwd)/example/sample.fasta outputs"
    exit 1
fi

echo "Input fasta file: $input_fasta"
echo "Output directory: $output_dir"

# rm -rf "$output_dir" features largeModels
mkdir -p "$output_dir" features largeModels
# chmod 777 "$output_dir" features largeModels

ESMpath="/opt/ESMDisPred"

# Get the filename from input path
fasta_filename=$(basename "$input_fasta")

docker run -it \
  --user $(id -u):$(id -g) \
  -e HOME=/opt/ESMDisPred \
  -e XDG_CACHE_HOME=/opt/ESMDisPred/.cache \
  -e TORCH_HOME=/opt/ESMDisPred/largeModels \
  -v "$input_fasta":"$ESMpath/example/$fasta_filename" \
  -v "$(pwd)/$output_dir":"$ESMpath/outputs":rw \
  -v "$(pwd)/features":"$ESMpath/features":rw \
  -v "$(pwd)/largeModels":"$ESMpath/largeModels":rw \
  -v "$(pwd)/run_ESMDisPred.sh":"$ESMpath/run_ESMDisPred.sh" \
  -v "$(pwd)/scripts/transformer_Inference.py":"$ESMpath/scripts/transformer_Inference.py" \
  -v "$(pwd)/scripts/preprocess.py":"$ESMpath/scripts/preprocess.py" \
  -v "$(pwd)/models":"$ESMpath/models" \
  -v "$(pwd)/requirements.txt":"$ESMpath/requirements.txt" \
  -v "$(pwd)/run_downloadLargeModels.sh":"$ESMpath/run_downloadLargeModels.sh" \
  wasicse/esmdispred:version2 \
  ./run_ESMDisPred.sh "$ESMpath/example/$fasta_filename" outputs