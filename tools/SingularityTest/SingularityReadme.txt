docker build -t wasicse/singularity - < Dockerfile

docker run -it --privileged -v /etc/localtime:/etc/localtime \
-v /home/mkabir3/Research/40_CAID3/12_FinalVersion/ESMDisPred/ESMDispS.def:/home/vscode/ESMDispS.def \
wasicse/singularity

sudo singularity  build ESMDispS.sif ESMDispS.def

singularity shell --writable --bind $input_fasta:/ESMDisPred/example/sample.fasta \
--bind $(pwd)/$output_dir:/ESMDisPred/outputs \
--bind $(pwd)/features:/ESMDisPred/features \
 ESMDispS.sif

sudo singularity shell ESMDispS.sif

v $input_fasta:/home/vscode/ESMDisPred/example/sample.fasta \
	-v $(pwd)/$output_dir:/home/vscode/ESMDisPred/outputs:rw \
	-v $(pwd)/features:/home/vscode/ESMDisPred/features:rw \



singularity pull esmdispred.sif docker://wasicse/esmdispred:latest

singularity run --writable-tmpfs esmdispred.sif