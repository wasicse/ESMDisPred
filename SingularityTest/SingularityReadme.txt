docker build -t wasicse/singularity - < Dockerfile

docker run --privileged -it wasicse/singularity

singularity pull esmdispred.sif docker://wasicse/esmdispred:latest

singularity run --writable-tmpfs esmdispred.sif