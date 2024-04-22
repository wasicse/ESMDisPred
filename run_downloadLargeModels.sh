

# Download large models 
mkdir -p largeModels
cd largeModels
wget -nc https://dl.fbaipublicfiles.com/fair-esm/models/esm2_t33_650M_UR50D.pt
wget -nc https://dl.fbaipublicfiles.com/fair-esm/models/esm1b_t33_650M_UR50S.pt
wget -nc https://www.cs.uno.edu/~mkabir3/Dispredict3.0/db/swissprot.psq
wget -nc https://www.cs.uno.edu/~mkabir3/Dispredict3.0/db/swissprot.phr
wget -nc https://www.cs.uno.edu/~mkabir3/Dispredict3.0/models/scaler.pkl
wget -nc https://www.cs.uno.edu/~mkabir3/Dispredict3.0/models/pca.pkl
wget -nc https://www.cs.uno.edu/~mkabir3/Dispredict3.0/models/model.pkl

# Create symbolic links
echo "Creating symbolic links"

cd -
ln -fs $(pwd)/largeModels/pca.pkl $(pwd)/tools/Dispredict3.0/models/pca.pkl
ln -fs $(pwd)/largeModels/scaler.pkl $(pwd)/tools/Dispredict3.0/models/scaler.pkl
ln -fs $(pwd)/largeModels/model.pkl $(pwd)/tools/Dispredict3.0/models/model.pkl
ln -fs $(pwd)/largeModels/swissprot.psq $(pwd)/tools/Dispredict3.0/tools/fldpnn/programs/blast-2.2.24/db/swissprot.psq
ln -fs $(pwd)/largeModels/swissprot.phr $(pwd)/tools/Dispredict3.0/tools/fldpnn/programs/blast-2.2.24/db/swissprot.phr
