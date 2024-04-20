#! /bin/bash

# docker build -t wasicse/esmdispred - < Dockerfile

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
	wasicse/esmdispred:latest  
	
	# \
	# -c /home/vscode/ESMDisPred/run_ESMDisPred.sh



# docker run -ti --rm \
# 	-v $input_fasta:/opt/ESMDisPred/example/sample.fasta \
# 	-v $(pwd)/$output_dir:/opt/ESMDisPred/hostoutput:rw \
# 	--entrypoint /bin/bash \
# 	wasicse/esmdispred:latest  \
# 	-c /opt/ESMDisPred/run_ESMDisPred.sh


# mkdir -p $output_dir/.cache
# mkdir -p $output_dir/.cache/hub
# mkdir -p $output_dir/.cache/checkpoints
# chmod -R 777 $output_dir
# docker run --user $(id -u) -ti --rm \
# 	-v $input_fasta:/opt/ESMDisPred/example/sample.fasta \
# 	-v $(pwd)/$output_dir/.cache:/opt/ESMDisPred/.cache:rw \
# 	-v $(pwd)/$output_dir/.cache/hub:/opt/ESMDisPred/.cache/hub:rw \
# 	-e TORCH_HOME='/opt/ESMDisPred/.cache' \
# 	-e MPLCONFIGDIR='/opt/ESMDisPred/.cache' \
# 	--entrypoint /bin/bash \
# 	wasicse/esmdispred:latest  
	
	
	# \
	# -c /opt/ESMDisPred//run_ESMDisPred.sh


		# -v $(pwd)/$output_dir:/opt/ESMDisPred/$output_dir:rw \