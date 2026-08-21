#!/bin/bash
# Run ESMDisPred via Singularity or Apptainer (HPC environments where Docker is unavailable).
#
# The .sif image is built from the published Docker image on first run.
# Subsequent runs reuse the cached .sif.
#
# Usage:
#   ./run_ESMDisPred_Singularity.sh [--clean] [--embeddings <dir>] <input_fasta> <output_dir> [model_option] [sif_path]
#
# model_option:
#   1 / ESMDisPred-1     DisPredict3.0 + ESM1
#   2 / ESMDisPred-2     DisPredict3.0 + ESM1 + ESM2
#   3 / ESMDisPred-2PDB  DisPredict3.0 + ESM1 + ESM2 + PDB
#   4 / ESMDisPred-DNN   CNN-Transformer hybrid
#   5 / all              Run all models
#
# sif_path (optional): path to an existing .sif file. Defaults to esmdispred.sif
#   in the same directory as this script.

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CLEAN_FLAG=""
embeddings_dir=""
ARGS=()
# --embeddings takes a value, so it cannot be a positional: the 4th positional
# slot is already sif_path, and passing a directory there would make the script
# treat it as a missing .sif and attempt a ~10 GB pull into it.
while [ $# -gt 0 ]; do
    case "$1" in
        --clean)      CLEAN_FLAG="--clean" ;;
        --embeddings) shift; embeddings_dir="${1:-}" ;;
        --embeddings=*) embeddings_dir="${1#*=}" ;;
        *)            ARGS+=("$1") ;;
    esac
    shift
done

input_fasta="${ARGS[0]:-}"
output_dir="${ARGS[1]:-}"
model_option="${ARGS[2]:-}"
sif_path="${ARGS[3]:-$SCRIPT_DIR/esmdispred.sif}"

ESMpath="/opt/ESMDisPred"
DOCKER_IMAGE="${ESMDISPRED_IMAGE:-wasicse/esmdispred:latest}"

# ----------------------------------------------------------------
# Usage check
# ----------------------------------------------------------------
if [ -z "$input_fasta" ] || [ -z "$output_dir" ]; then
    echo "Usage: $0 [--clean] [--embeddings <dir>] <input_fasta> <output_dir> [model_option] [sif_path]"
    echo ""
    echo "  --embeddings <dir>  Directory of pre-computed ESM2 embeddings (.npy/.h5 per protein, CAID)"
    echo ""
    echo "Example (non-interactive):"
    echo "  $0 \$(pwd)/example/sample.fasta outputs 4"
    echo "  $0 \$(pwd)/example/sample.fasta outputs ESMDisPred-DNN"
    echo "  $0 \$(pwd)/example/sample.fasta outputs all"
    echo ""
    echo "Model options:"
    echo "  1 or ESMDisPred-1     - DisPredict3.0 + ESM1"
    echo "  2 or ESMDisPred-2     - DisPredict3.0 + ESM1 + ESM2"
    echo "  3 or ESMDisPred-2PDB  - DisPredict3.0 + ESM1 + ESM2 + PDB"
    echo "  4 or ESMDisPred-DNN   - CNN-Transformer hybrid"
    echo "  5 or all              - Run all models"
    exit 1
fi

# ----------------------------------------------------------------
# Resolve absolute paths (so bind mounts work regardless of cwd)
# ----------------------------------------------------------------
[[ "$input_fasta" == /* ]] || input_fasta="$(pwd)/$input_fasta"
[[ "$output_dir"  == /* ]] || output_dir="$(pwd)/$output_dir"

# Pre-computed ESM2 embeddings (CAID): bound read-only, passed as the 4th
# argument to run_ESMDisPred.sh using its container-side path.
EMB_BIND=()
EMB_ARG=""
if [ -n "$embeddings_dir" ]; then
    [[ "$embeddings_dir" == /* ]] || embeddings_dir="$(pwd)/$embeddings_dir"
    if [ ! -d "$embeddings_dir" ]; then
        echo "ERROR: --embeddings is not a directory: $embeddings_dir"
        exit 1
    fi
    EMB_BIND=(-B "$embeddings_dir":"$ESMpath/embeddings":ro)
    EMB_ARG="$ESMpath/embeddings"
fi

# ----------------------------------------------------------------
# Detect Apptainer or Singularity (HPC clusters vary)
# ----------------------------------------------------------------
if command -v apptainer &>/dev/null; then
    SIF_CMD="apptainer"
elif command -v singularity &>/dev/null; then
    SIF_CMD="singularity"
else
    echo "ERROR: Neither apptainer nor singularity found in PATH."
    echo "       Load the module first, e.g.: module load apptainer"
    exit 1
fi
echo "Using: $SIF_CMD"

# ----------------------------------------------------------------
# Build / pull the .sif image if not already present
# ----------------------------------------------------------------
if [ ! -f "$sif_path" ]; then
    echo "No .sif found at $sif_path — pulling from Docker Hub..."
    echo "  Source image : $DOCKER_IMAGE"
    echo "  Destination  : $sif_path"
    echo ""
    echo "  This downloads ~10 GB on first run. Subsequent runs reuse the cached .sif."
    echo ""
    $SIF_CMD pull "$sif_path" "docker://$DOCKER_IMAGE"
else
    echo "Using existing image: $sif_path"
fi

# ----------------------------------------------------------------
# --clean: wipe host-side caches before bind-mounting (same rationale as Docker)
# ----------------------------------------------------------------
if [ -n "$CLEAN_FLAG" ]; then
    echo "→ --clean: removing previous run files (host-side)..."
    rm -rf "$SCRIPT_DIR/features"
    rm -rf "$output_dir"
    echo "  Removed: $SCRIPT_DIR/features"
    echo "  Removed: $output_dir"
    echo "  Note: largeModels/ is preserved"
fi

# ----------------------------------------------------------------
# Prepare host-side directories (mirrors Docker script)
# ----------------------------------------------------------------
mkdir -p "$output_dir" "$SCRIPT_DIR/features" "$SCRIPT_DIR/largeModels"

fasta_filename="$(basename "$input_fasta")"

echo ""
echo "Input fasta : $input_fasta"
echo "Output dir  : $output_dir"
echo "Model option: ${model_option:-interactive}"
echo ""

# ----------------------------------------------------------------
# Run
#
# DisPredict3.0 / fldpnn writes temp files to its own directory when
# writable, and automatically falls back to /tmp otherwise.
# /tmp is always writable in Singularity (host-mounted by default),
# so --writable-tmpfs is NOT required and is intentionally omitted
# for maximum portability across HPC clusters.
#
# -B src:dst  bind-mount host path into the container
#             (equivalent to Docker's -v src:dst)
#
# All paths passed to run_ESMDisPred.sh must use container-side paths.
# ----------------------------------------------------------------
# DisPredict3.0 binaries (psiblast, DFLpred, fMoRFpred) write temp files to
# their own program directories inside the SIF, which is read-only by default.
# --writable-tmpfs overlays a tmpfs on the container filesystem to allow this.
# If unavailable on the cluster, ask your sysadmin or use --overlay instead.
WRITABLE_OPT="--writable-tmpfs"
if ! $SIF_CMD exec --writable-tmpfs "$sif_path" true 2>/dev/null; then
    echo "WARNING: --writable-tmpfs not available — DisPredict3.0 temp files may fail."
    echo "         Ask your sysadmin to enable it, or contact us for an overlay-based workaround."
    WRITABLE_OPT=""
fi

$SIF_CMD exec --nv $WRITABLE_OPT \
    -B "$input_fasta":"$ESMpath/example/$fasta_filename" \
    -B "$output_dir":"$ESMpath/outputs" \
    -B "$SCRIPT_DIR/features":"$ESMpath/features" \
    -B "$SCRIPT_DIR/largeModels":"$ESMpath/largeModels" \
    -B "$SCRIPT_DIR/run_ESMDisPred.sh":"$ESMpath/run_ESMDisPred.sh" \
    -B "$SCRIPT_DIR/run_downloadLargeModels.sh":"$ESMpath/run_downloadLargeModels.sh" \
    -B "$SCRIPT_DIR/scripts/run_Dispredict3.sh":"$ESMpath/scripts/run_Dispredict3.sh" \
    -B "$SCRIPT_DIR/scripts/run_ESMDisPred.py":"$ESMpath/scripts/run_ESMDisPred.py" \
    -B "$SCRIPT_DIR/scripts/run_ESM2.py":"$ESMpath/scripts/run_ESM2.py" \
    -B "$SCRIPT_DIR/scripts/transformer_Inference.py":"$ESMpath/scripts/transformer_Inference.py" \
    -B "$SCRIPT_DIR/scripts/preprocess.py":"$ESMpath/scripts/preprocess.py" \
    -B "$SCRIPT_DIR/tools/Dispredict3.0/script/Dispredict3.0.py":"$ESMpath/tools/Dispredict3.0/script/Dispredict3.0.py" \
    -B "$SCRIPT_DIR/tools/Dispredict3.0/tools/fldpnn/run_flDPnn.py":"$ESMpath/tools/Dispredict3.0/tools/fldpnn/run_flDPnn.py" \
    -B "$SCRIPT_DIR/tools/Dispredict3.0/tools/fldpnn/DisoComb.sh":"$ESMpath/tools/Dispredict3.0/tools/fldpnn/DisoComb.sh" \
    -B "$SCRIPT_DIR/models":"$ESMpath/models" \
    -B "$SCRIPT_DIR/requirements.txt":"$ESMpath/requirements.txt" \
    "${EMB_BIND[@]}" \
    "$sif_path" \
    "$ESMpath/run_ESMDisPred.sh" \
        "$ESMpath/example/$fasta_filename" \
        "$ESMpath/outputs" \
        "$model_option" \
        "$EMB_ARG"
