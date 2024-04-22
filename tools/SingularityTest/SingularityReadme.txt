docker build -t wasicse/singularity - < Dockerfile

docker run -it --privileged -v /etc/localtime:/etc/localtime \
-v $(pwd)/ESMDispS.def:/home/vscode/ESMDispS.def \
wasicse/singularity

sudo singularity  build ESMDispS.sif ESMDispS.def
sudo  singularity shell --writable-tmpfs  ESMDispS.sif
cd /ESMDisPred && ./run_ESMDisPred.sh


singularity run --writable-tmpfs esmdispred.sif
cd /opt/ESMDisPred  && ./run_ESMDisPred.sh

singularity pull --writable ubuntu.sif docker://ubuntu
singularity run --writable-tmpfs ubuntu.sif

sudo singularity build --writable lolcow.img shub://GodloveD/lolcow
sudo singularity shell --writable ubuntu.sif





singularity pull esmdispred.sif docker://wasicse/esmdispredroot:latest
input_fasta="$(pwd)/example/sample.fasta"
output_dir="outputs"
sudo singularity run --writable-tmpfs \
	-B $input_fasta:/opt/ESMDisPred/example/sample.fasta \
	-B $(pwd)/$output_dir:/opt/ESMDisPred/outputs:rw /home/vscode/esmdispred.sif
cd /opt/ESMDisPred  && ./run_ESMDisPred.sh


sudo singularity  build ESMDispS.sif ESMDispS.def
input_fasta="$(pwd)/example/sample.fasta"
output_dir="outputs"
sudo singularity run --writable-tmpfs \
	-B $input_fasta:/ESMDisPred/example/sample.fasta \
	-B $(pwd)/$output_dir:/ESMDisPred/outputs:rw /home/vscode/ESMDispS.sif
cd /ESMDisPred  && ./run_ESMDisPred.sh