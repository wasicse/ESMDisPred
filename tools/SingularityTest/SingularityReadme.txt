docker build -t wasicse/singularity - < Dockerfile

docker run -it --privileged -v /etc/localtime:/etc/localtime  wasicse/singularity

singularity pull esmdispred.sif docker://wasicse/esmdispred:latest

singularity run --writable-tmpfs esmdispred.sif