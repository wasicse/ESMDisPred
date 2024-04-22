#! /bin/bash

# Download large models 
mkdir -p largeModels
cd largeModels
wget -nvc https://dl.fbaipublicfiles.com/fair-esm/models/esm2_t33_650M_UR50D.pt
wget -nvc https://dl.fbaipublicfiles.com/fair-esm/models/esm1b_t33_650M_UR50S.pt
wget -nvc https://www.cs.uno.edu/~mkabir3/Dispredict3.0/db/swissprot.psq
wget -nvc https://www.cs.uno.edu/~mkabir3/Dispredict3.0/db/swissprot.phr
wget -nvc https://www.cs.uno.edu/~mkabir3/Dispredict3.0/models/scaler.pkl
wget -nvc https://www.cs.uno.edu/~mkabir3/Dispredict3.0/models/pca.pkl
wget -nvc https://www.cs.uno.edu/~mkabir3/Dispredict3.0/models/model.pkl
wget -nvc https://dl.fbaipublicfiles.com/fair-esm/regression/esm1b_t33_650M_UR50S-contact-regression.pt
wget -nvc https://dl.fbaipublicfiles.com/fair-esm/regression/esm2_t33_650M_UR50D-contact-regression.pt

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


