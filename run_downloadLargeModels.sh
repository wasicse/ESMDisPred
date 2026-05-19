#!/bin/bash
# Works when called from any directory (local, Docker, Singularity exec).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$SCRIPT_DIR/largeModels"
cd "$SCRIPT_DIR/largeModels"

echo "Checking and downloading required models..."

downloads=0

download_file() {
    if [ ! -f "$1" ]; then
        if ! wget -q --spider --timeout=10 "$2" 2>/dev/null; then
            echo "  WARNING: offline or unreachable — cannot download $1"
            echo "           Mount or copy the file manually to: $(pwd)/$1"
            return 0
        fi
        echo "  Downloading: $1"
        wget -q "$2" -O "$1"
        downloads=$((downloads + 1))
    fi
}

# SwissProt DB files
download_file "swissprot.psq" "https://huggingface.co/wasicse/dispred/resolve/main/swissprot.psq"
download_file "swissprot.phr" "https://huggingface.co/wasicse/dispred/resolve/main/swissprot.phr"

# Dispredict model files
download_file "scaler.pkl" "https://huggingface.co/wasicse/dispred/resolve/main/scaler.pkl"
download_file "pca.pkl"    "https://huggingface.co/wasicse/dispred/resolve/main/pca.pkl"
download_file "model.pkl"  "https://huggingface.co/wasicse/dispred/resolve/main/model.pkl"

# ESMDisPred-DNN model
download_file "best.pt" "https://huggingface.co/wasicse/dispred/resolve/main/best.pt"

# ESM model files
download_file "esm1b_t33_650M_UR50S-contact-regression.pt" "https://huggingface.co/wasicse/dispred/resolve/main/esm1b_t33_650M_UR50S-contact-regression.pt"
download_file "esm2_t33_650M_UR50D-contact-regression.pt"  "https://huggingface.co/wasicse/dispred/resolve/main/esm2_t33_650M_UR50D-contact-regression.pt"
download_file "esm2_t33_650M_UR50D.pt"                     "https://huggingface.co/wasicse/dispred/resolve/main/esm2_t33_650M_UR50D.pt"
download_file "esm1b_t33_650M_UR50S.pt"                    "https://huggingface.co/wasicse/dispred/resolve/main/esm1b_t33_650M_UR50S.pt"

if [ $downloads -eq 0 ]; then
    echo "All models already downloaded."
else
    echo "Downloaded $downloads new file(s)."
fi

cd "$SCRIPT_DIR"

# Symlinks — all using absolute paths anchored to SCRIPT_DIR.
# ln may fail silently in non-root Docker if the parent dir is read-only;
# the container's baked-in symlinks are used as fallback in that case.
mkdir -p "$SCRIPT_DIR/models" 2>/dev/null || true
ln -fs "$SCRIPT_DIR/largeModels/best.pt" "$SCRIPT_DIR/models/best.pt" 2>/dev/null || true

mkdir -p "$SCRIPT_DIR/tools/Dispredict3.0/models" 2>/dev/null || true
ln -fs "$SCRIPT_DIR/largeModels/pca.pkl"    "$SCRIPT_DIR/tools/Dispredict3.0/models/pca.pkl"    2>/dev/null || true
ln -fs "$SCRIPT_DIR/largeModels/scaler.pkl" "$SCRIPT_DIR/tools/Dispredict3.0/models/scaler.pkl" 2>/dev/null || true
ln -fs "$SCRIPT_DIR/largeModels/model.pkl"  "$SCRIPT_DIR/tools/Dispredict3.0/models/model.pkl"  2>/dev/null || true

mkdir -p "$SCRIPT_DIR/tools/Dispredict3.0/tools/fldpnn/programs/blast-2.2.24/db" 2>/dev/null || true
ln -fs "$SCRIPT_DIR/largeModels/swissprot.psq" "$SCRIPT_DIR/tools/Dispredict3.0/tools/fldpnn/programs/blast-2.2.24/db/swissprot.psq" 2>/dev/null || true
ln -fs "$SCRIPT_DIR/largeModels/swissprot.phr" "$SCRIPT_DIR/tools/Dispredict3.0/tools/fldpnn/programs/blast-2.2.24/db/swissprot.phr" 2>/dev/null || true

mkdir -p "$SCRIPT_DIR/.cache/hub/checkpoints" 2>/dev/null || true
ln -fs "$SCRIPT_DIR/largeModels/esm1b_t33_650M_UR50S.pt"                    "$SCRIPT_DIR/.cache/hub/checkpoints/esm1b_t33_650M_UR50S.pt"                    2>/dev/null || true
ln -fs "$SCRIPT_DIR/largeModels/esm2_t33_650M_UR50D.pt"                     "$SCRIPT_DIR/.cache/hub/checkpoints/esm2_t33_650M_UR50D.pt"                     2>/dev/null || true
ln -fs "$SCRIPT_DIR/largeModels/esm1b_t33_650M_UR50S-contact-regression.pt" "$SCRIPT_DIR/.cache/hub/checkpoints/esm1b_t33_650M_UR50S-contact-regression.pt" 2>/dev/null || true
ln -fs "$SCRIPT_DIR/largeModels/esm2_t33_650M_UR50D-contact-regression.pt"  "$SCRIPT_DIR/.cache/hub/checkpoints/esm2_t33_650M_UR50D-contact-regression.pt"  2>/dev/null || true

echo "Symbolic links updated (failures silenced — baked-in container links used as fallback)."
