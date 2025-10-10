#! /bin/bash

# Download large models 
mkdir -p largeModels
cd largeModels
echo "Downloading Dispredict3.0 models from Hugging Face"

# SwissProt DB files
wget -nc https://huggingface.co/wasicse/dispred/resolve/main/swissprot.psq
wget -nc https://huggingface.co/wasicse/dispred/resolve/main/swissprot.phr

# Dispredict model files
wget -nc https://huggingface.co/wasicse/dispred/resolve/main/scaler.pkl
wget -nc https://huggingface.co/wasicse/dispred/resolve/main/pca.pkl
wget -nc https://huggingface.co/wasicse/dispred/resolve/main/model.pkl

echo "Downloading ESM models from Hugging Face"

# ESM model files (ensure they were uploaded)
wget -nc https://huggingface.co/wasicse/dispred/resolve/main/esm1b_t33_650M_UR50S-contact-regression.pt
wget -nc https://huggingface.co/wasicse/dispred/resolve/main/esm2_t33_650M_UR50D-contact-regression.pt
wget -nc https://huggingface.co/wasicse/dispred/resolve/main/esm2_t33_650M_UR50D.pt
wget -nc https://huggingface.co/wasicse/dispred/resolve/main/esm1b_t33_650M_UR50S.pt
# Create symbolic links
echo "Creating symbolic links"

cd -
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


