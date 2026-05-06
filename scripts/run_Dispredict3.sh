#! /bin/bash
set -e

# Works when called from any directory (local, Docker, Singularity exec).
# Both arguments must be absolute paths (run_ESMDisPred.sh ensures this).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

input_fasta=$1
output_dir=$2
export LD_LIBRARY_PATH="$PROJECT_ROOT/lib:${LD_LIBRARY_PATH:-}"
export TF_CPP_MIN_LOG_LEVEL="${TF_CPP_MIN_LOG_LEVEL:-3}"

echo "Input fasta file: $input_fasta"
echo "Output directory: $output_dir"

mkdir -p "$output_dir/predictions"
mkdir -p "$output_dir/features"

cd "$PROJECT_ROOT/tools/Dispredict3.0/script"
cp tcsh /tmp/
source "$PROJECT_ROOT/.venv/bin/activate"
"$PROJECT_ROOT/.venv/bin/python" Dispredict3.0.py -f "$input_fasta" -o "$output_dir"
rm -rf "$PROJECT_ROOT/tools/Dispredict3.0/tools/fldpnn/pyflDPnn_tmp"*/
rm -rf "$PROJECT_ROOT/tools/Dispredict3.0/tools/fldpnn/output"/*

mkdir -p "$PROJECT_ROOT/outputs/disorder/Dispredict3.0"
cp "$output_dir/predictions"/* "$PROJECT_ROOT/outputs/disorder/Dispredict3.0/"

cd "$SCRIPT_DIR"
