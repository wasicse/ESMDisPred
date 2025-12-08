#!/bin/bash

# Download large models 
mkdir -p largeModels
cd largeModels

echo "Checking and downloading required models..."

# Track if any downloads happened
downloads=0

# Function to download silently and track
download_file() {
    if [ ! -f "$1" ]; then
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
download_file "pca.pkl" "https://huggingface.co/wasicse/dispred/resolve/main/pca.pkl"
download_file "model.pkl" "https://huggingface.co/wasicse/dispred/resolve/main/model.pkl"

# ESM model files
download_file "esm1b_t33_650M_UR50S-contact-regression.pt" "https://huggingface.co/wasicse/dispred/resolve/main/esm1b_t33_650M_UR50S-contact-regression.pt"
download_file "esm2_t33_650M_UR50D-contact-regression.pt" "https://huggingface.co/wasicse/dispred/resolve/main/esm2_t33_650M_UR50D-contact-regression.pt"
download_file "esm2_t33_650M_UR50D.pt" "https://huggingface.co/wasicse/dispred/resolve/main/esm2_t33_650M_UR50D.pt"
download_file "esm1b_t33_650M_UR50S.pt" "https://huggingface.co/wasicse/dispred/resolve/main/esm1b_t33_650M_UR50S.pt"

# Summary message
if [ $downloads -eq 0 ]; then
    echo "All models already downloaded."
else
    echo "Downloaded $downloads new file(s)."
fi

cd - > /dev/null

# Create symbolic links (silently)
mkdir -p tools/Dispredict3.0/models
ln -fs $(pwd)/largeModels/pca.pkl $(pwd)/tools/Dispredict3.0/models/pca.pkl
ln -fs $(pwd)/largeModels/scaler.pkl $(pwd)/tools/Dispredict3.0/models/scaler.pkl
ln -fs $(pwd)/largeModels/model.pkl $(pwd)/tools/Dispredict3.0/models/model.pkl
ln -fs $(pwd)/largeModels/swissprot.psq $(pwd)/tools/Dispredict3.0/tools/fldpnn/programs/blast-2.2.24/db/swissprot.psq
ln -fs $(pwd)/largeModels/swissprot.phr $(pwd)/tools/Dispredict3.0/tools/fldpnn/programs/blast-2.2.24/db/swissprot.phr

mkdir -p ./.cache/hub/checkpoints
ln -fs $(pwd)/largeModels/esm1b_t33_650M_UR50S.pt $(pwd)/.cache/hub/checkpoints/esm1b_t33_650M_UR50S.pt
ln -fs $(pwd)/largeModels/esm2_t33_650M_UR50D.pt $(pwd)/.cache/hub/checkpoints/esm2_t33_650M_UR50D.pt
ln -fs $(pwd)/largeModels/esm1b_t33_650M_UR50S-contact-regression.pt $(pwd)/.cache/hub/checkpoints/esm1b_t33_650M_UR50S-contact-regression.pt
ln -fs $(pwd)/largeModels/esm2_t33_650M_UR50D-contact-regression.pt $(pwd)/.cache/hub/checkpoints/esm2_t33_650M_UR50D-contact-regression.pt

echo "Symbolic links created."
