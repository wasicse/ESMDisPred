#! /bin/bash



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
# docker run -it \
# 	-v $input_fasta:/home/vscode/ESMDisPred/example/sample.fasta \
# 	-v $(pwd)/$output_dir:/home/vscode/ESMDisPred/outputs:rw \
# 	-v $(pwd)/features:/home/vscode/ESMDisPred/features:rw \
# 	--entrypoint /bin/bash \
# 	wasicse/esmdispred:latest \
# 	-c /home/vscode/ESMDisPred/run_ESMDisPred.sh

singularity pull esmdispred.sif docker://wasicse/esmdispred:latest

singularity run --writable-tmpfs esmdispred.sif

# mount a local directory to the container
singularity exec --writable-tmpfs -B $(pwd)/example:/home/vscode/ESMDisPred/example esmdispred.sif bash -c "./run_ESMDisPred.sh"

# copy the ouptut files from container to local directory
singularity exec --writable-tmpfs -B $(pwd)/example:/home/vscode/ESMDisPred/example esmdispred.sif cp -r /home/vscode/ESMDisPred/outputs /home/vscode/ESMDisPred/singularityOutputs















# # Input arguments
# input_fasta=$1
# output_dir=$2

# echo "Input fasta file: $input_fasta"

# singularity pull docker://wasicse/esmdispred:latest 

# singularity exec docker://wasicse/esmdispred:latest  echo "Hello Dinosaur!"

# docker run --user $(id -u) -ti --rm \
# 	-v $input_fasta:/opt/ESMDisPred/example/sample.fasta \
# 	-v $(pwd)/$output_dir:/opt/ESMDisPred/$output_dir:rw \	
# 	--entrypoint /bin/bash \
# 	wasicse/esmdispred:latest  \
# 	-c "git pull; \
# 	./run_ESMDisPred.sh
# singularity  exec  <image path or url> cp <file in container> .


# # convert this to a singularity script
# # singularity pull docker://wasicse/esmdispred:latest
# # singularity exec docker://wasicse/esmdispred:latest  echo "Hello Dinosaur!"

# # singularity run docker://wasicse/esmdispred:latest  echo "Hello Dinosaur!"


# singularity shell docker://ubuntu:latest

# singularity run docker://ubuntu:latest

# singularity exec docker://ubuntu:latest echo "Hello Dinosaur!"


# singularity pull docker://ubuntu:latest

# singularity build ubuntu.img docker://ubuntu:latest