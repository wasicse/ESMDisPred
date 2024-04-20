#! /bin/bash

docker build -t wasicse/esmdispred - < Dockerfile

# Input arguments
# input_fasta=$1
# output_dir=$2


input_fasta="$(pwd)/example/sample.fasta"
output_dir="outputs"


echo "Input fasta file: $input_fasta"
echo "Output directory: $output_dir"
mkdir -p $output_dir
chmod -R 777 $output_dir
mkdir -p features
chmod -R 777 features
# --rm 
echo $(pwd)/$output_dir
docker run -it \
	-v $input_fasta:/home/vscode/ESMDisPred/example/sample.fasta \
	-v $(pwd)/$output_dir:/home/vscode/ESMDisPred/outputs:rw \
	-v $(pwd)/features:/home/vscode/ESMDisPred/features:rw \
	--entrypoint /bin/bash \
	wasicse/esmdispred:latest \
	-c /home/vscode/ESMDisPred/run_ESMDisPred.sh



