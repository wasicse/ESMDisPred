FROM debian:buster-slim
RUN mkdir -p /usr/share/man/man1 /usr/share/man/man2

RUN apt-get update && \
apt-get install -y --no-install-recommends make build-essential libssl-dev  wget curl llvm libidn11 openjdk-11-jre git nano tcsh sudo 

WORKDIR "/opt"

git clone https://github.com/wasicse/ESMDisPred.git

WORKDIR "/opt/Dispredict3.0"

ENTRYPOINT [ "/bin/bash" ]


