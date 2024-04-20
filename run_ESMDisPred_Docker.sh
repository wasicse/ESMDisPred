#! /bin/bash

# Input arguments
input_fasta=$1
output_dir=$2

echo "Input fasta file: $input_fasta"
echo "Output directory: $output_dir"
mkdir -p $output_dir
docker run --user $(id -u) -ti --rm \
	-v $input_fasta:/opt/ESMDisPred/example/sample.fasta \
	--entrypoint /bin/bash \
	wasicse/esmdispred:latest  \
	-c /opt/ESMDisPred//run_ESMDisPred.sh


		# -v $(pwd)/$output_dir:/opt/ESMDisPred/$output_dir:rw \