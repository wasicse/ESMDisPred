docker build -t wasicse/singularity - < Dockerfile

docker run -it --privileged -v /etc/localtime:/etc/localtime \
-v $(pwd)/ESMDispS.def:/home/vscode/ESMDispS.def \
wasicse/singularity

git clone https://github.com/wasicse/ESMDisPred.git

