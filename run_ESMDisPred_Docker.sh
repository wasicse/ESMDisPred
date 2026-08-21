#!/bin/bash
set -e

CLEAN_FLAG=""
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --clean) CLEAN_FLAG="--clean" ;;
        *)       ARGS+=("$arg") ;;
    esac
done

input_fasta=${ARGS[0]:-}
output_dir=${ARGS[1]:-}
model_option=${ARGS[2]:-}
embeddings_dir=${ARGS[3]:-}   # optional: pre-computed ESM2 embeddings dir (CAID)

if [ -z "$input_fasta" ] || [ -z "$output_dir" ]; then
    echo "Usage: $0 [--clean] <input_fasta> <output_dir> [model_option] [embeddings_dir]"
    echo ""
    echo "Example (interactive):"
    echo "  $0 \$(pwd)/example/sample.fasta outputs"
    echo ""
    echo "Example (non-interactive):"
    echo "  $0 \$(pwd)/example/sample.fasta outputs 3"
    echo "  $0 \$(pwd)/example/sample.fasta outputs ESMDisPred-2PDB"
    echo "  $0 \$(pwd)/example/sample.fasta outputs all"
    echo ""
    echo "Example (CAID pre-computed ESM2 embeddings):"
    echo "  $0 \$(pwd)/example/sample.fasta outputs 3 \$(pwd)/embeddings"
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

ESMpath="/opt/ESMDisPred"
# Override to test a candidate build or pin a release, e.g.
#   ESMDISPRED_IMAGE=wasicse/esmdispred:caid4 ./run_ESMDisPred_Docker.sh ...
DOCKER_IMAGE="${ESMDISPRED_IMAGE:-wasicse/esmdispred:latest}"
fasta_filename=$(basename "$input_fasta")

# Resolve output_dir to absolute path early (needed for --clean and bind mount)
if [[ "$output_dir" = /* ]]; then
    output_dir_abs="$output_dir"
else
    output_dir_abs="$(pwd)/$output_dir"
fi

# --clean: wipe host-side caches before bind-mounting them into Docker.
# We EMPTY the directories rather than deleting them to preserve directory
# inodes — NFS-mounted home directories return ESTALE (stale file handle)
# inside the container when a directory is deleted and recreated with a new
# inode between the rm and the docker run.
if [ -n "$CLEAN_FLAG" ]; then
    echo "→ --clean: removing previous run files (host-side)..."
    mkdir -p "$(pwd)/features" "$output_dir_abs"
    find "$(pwd)/features" -mindepth 1 -delete 2>/dev/null || true
    find "$output_dir_abs"  -mindepth 1 -delete 2>/dev/null || true
    echo "  Cleared: $(pwd)/features"
    echo "  Cleared: $output_dir_abs"
    echo "  Note: largeModels/ is preserved"
fi

# Create necessary directories
mkdir -p "$output_dir" features largeModels

# Handle both relative and absolute paths for output_dir
if [[ "$output_dir" = /* ]]; then
    # Absolute path - use as is
    output_dir_abs="$output_dir"
else
    # Relative path - prepend $(pwd)
    output_dir_abs="$(pwd)/$output_dir"
fi

# Pre-computed ESM2 embeddings (CAID): bind the host directory read-only and
# hand run_ESMDisPred.sh the container-side path as its 4th argument.
EMB_MOUNT=()
EMB_ARG=""
if [ -n "$embeddings_dir" ]; then
    [[ "$embeddings_dir" = /* ]] || embeddings_dir="$(pwd)/$embeddings_dir"
    if [ ! -d "$embeddings_dir" ]; then
        echo "ERROR: embeddings_dir is not a directory: $embeddings_dir"
        exit 1
    fi
    EMB_MOUNT=(-v "$embeddings_dir":"$ESMpath/embeddings":ro)
    EMB_ARG="$ESMpath/embeddings"
    echo "Embeddings dir: $embeddings_dir"
fi

TTY_FLAG=""; [ -t 0 ] && TTY_FLAG="-t"
docker run -i $TTY_FLAG \
  $(docker info 2>/dev/null | grep -q "Runtimes.*nvidia" && echo "--gpus all") \
  --user $(id -u):$(id -g) \
  -e HOME=/opt/ESMDisPred \
  -e XDG_CACHE_HOME=/opt/ESMDisPred/.cache \
  -e TORCH_HOME=/opt/ESMDisPred/largeModels \
  -v "$input_fasta":"$ESMpath/example/$fasta_filename" \
  -v "$output_dir_abs":"$ESMpath/outputs":rw \
  -v "$(pwd)/features":"$ESMpath/features":rw \
  -v "$(pwd)/largeModels":"$ESMpath/largeModels":rw \
  -v "$(pwd)/run_ESMDisPred.sh":"$ESMpath/run_ESMDisPred.sh" \
  -v "$(pwd)/scripts/run_Dispredict3.sh":"$ESMpath/scripts/run_Dispredict3.sh" \
  -v "$(pwd)/scripts/run_ESMDisPred.py":"$ESMpath/scripts/run_ESMDisPred.py" \
  -v "$(pwd)/scripts/run_ESM2.py":"$ESMpath/scripts/run_ESM2.py" \
  -v "$(pwd)/tools/Dispredict3.0/script/Dispredict3.0.py":"$ESMpath/tools/Dispredict3.0/script/Dispredict3.0.py" \
  -v "$(pwd)/tools/Dispredict3.0/tools/fldpnn/run_flDPnn.py":"$ESMpath/tools/Dispredict3.0/tools/fldpnn/run_flDPnn.py" \
  -v "$(pwd)/tools/Dispredict3.0/tools/fldpnn/DisoComb.sh":"$ESMpath/tools/Dispredict3.0/tools/fldpnn/DisoComb.sh" \
  -v "$(pwd)/scripts/transformer_Inference.py":"$ESMpath/scripts/transformer_Inference.py" \
  -v "$(pwd)/scripts/preprocess.py":"$ESMpath/scripts/preprocess.py" \
  -v "$(pwd)/models":"$ESMpath/models" \
  -v "$(pwd)/requirements.txt":"$ESMpath/requirements.txt" \
  -v "$(pwd)/run_downloadLargeModels.sh":"$ESMpath/run_downloadLargeModels.sh" \
  "${EMB_MOUNT[@]}" \
  "$DOCKER_IMAGE" \
  ./run_ESMDisPred.sh "$ESMpath/example/$fasta_filename" outputs "$model_option" "$EMB_ARG"