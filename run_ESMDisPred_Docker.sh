#! /bin/bash

# Input arguments
input_fasta=$1
output_dir=$2

# if no input arguments
if [ -z "$input_fasta" ] || [ -z "$output_dir" ]
then
	echo "Please provide input fasta file and output directory"
	exit 1
fi

# input_fasta="$(pwd)/example/sample.fasta"
# output_dir="outputs"
echo "Input fasta file: $input_fasta"
echo "Output directory: $output_dir"
mkdir -p $output_dir
chmod  777 $output_dir
mkdir -p features
chmod  777 features
# --rm 

# ESMpath="/home/vscode/ESMDisPred"
ESMpath="/opt/ESMDisPred"
docker run  -it \
	-v $input_fasta:$ESMpath/example/sample.fasta \
	-v $(pwd)/$output_dir:$ESMpath/outputs:rw \
	-v $(pwd)/features:$ESMpath/features:rw \
	-v $(pwd)/largeModels:$ESMpath/largeModels:rw \
	--entrypoint /bin/bash \
	wasicse/esmdispred:latest 
	
	# \
	# -c $ESMpath/run_ESMDisPred.sh ; /bin/bash




