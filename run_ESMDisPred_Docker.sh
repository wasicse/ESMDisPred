#! /bin/bash
set -e

input_fasta=$1
output_dir=$2

if [ -z "$input_fasta" ] || [ -z "$output_dir" ]; then
    echo "Please provide input fasta file and output directory"
    exit 1
fi

echo "Input fasta file: $input_fasta"
echo "Output directory: $output_dir"

mkdir -p "$output_dir" features largeModels
chmod 777 "$output_dir" features largeModels

ESMpath="/opt/ESMDisPred"

docker run  -it \
  -v "$input_fasta":"$ESMpath/example/sample.fasta" \
  -v "$(pwd)/$output_dir":"$ESMpath/outputs":rw \
  -v "$(pwd)/features":"$ESMpath/features":rw \
  -v "$(pwd)/largeModels":"$ESMpath/largeModels":rw \
  -v "$(pwd)/run_ESMDisPred.sh":"$ESMpath/run_ESMDisPred.sh" \
  -v "$(pwd)/scripts/transformer_Inference.py":"$ESMpath/scripts/transformer_Inference.py" \
  -v "$(pwd)/scripts/preprocess.py":"$ESMpath/scripts/preprocess.py" \
  -v "$(pwd)/models":"$ESMpath/models" \
  -v "$(pwd)/requirements.txt":"$ESMpath/requirements.txt" \
  --entrypoint /bin/bash \
  wasicse/esmdispred:version2 
  # -c '
  #   echo "→ Checking Conda setup..."
  #   eval "$(/opt/.pyenv/versions/miniconda3-4.7.12/bin/conda shell.bash hook)"

  #   # Create or reuse env
  #   if conda info --envs | grep -q "py39"; then
  #       echo "→ Using existing Conda environment py39"
  #   else
  #       echo "→ Creating Conda environment py39"
  #       conda create -y -n py39 python=3.9
  #   fi

  #   conda activate py39

  #   echo "→ Installing dependencies from requirements.txt..."
  #   pip install --no-cache-dir -r /opt/ESMDisPred/requirements.txt

  #   echo "→ Dropping into interactive bash shell..."
  #   exec bash
  # '
