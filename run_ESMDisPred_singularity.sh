#! /bin/bash

# Input arguments
input_fasta=$1
output_dir=$2

echo "Input fasta file: $input_fasta"

singularity pull docker://wasicse/esmdispred:latest 

singularity exec docker://wasicse/esmdispred:latest  echo "Hello Dinosaur!"

docker run --user $(id -u) -ti --rm \
	-v $input_fasta:/opt/ESMDisPred/example/sample.fasta \
	-v $(pwd)/$output_dir:/opt/ESMDisPred/$output_dir:rw \	
	--entrypoint /bin/bash \
	wasicse/esmdispred:latest  \
	-c "git pull; \
	./run_ESMDisPred.sh
singularity  exec  <image path or url> cp <file in container> .


# convert this to a singularity script
# singularity pull docker://wasicse/esmdispred:latest
# singularity exec docker://wasicse/esmdispred:latest  echo "Hello Dinosaur!"

# singularity run docker://wasicse/esmdispred:latest  echo "Hello Dinosaur!"


singularity shell docker://ubuntu:latest

singularity run docker://ubuntu:latest

singularity exec docker://ubuntu:latest echo "Hello Dinosaur!"


singularity pull docker://ubuntu:latest

singularity build ubuntu.img docker://ubuntu:latest