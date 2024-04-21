FROM ubuntu
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Install 
RUN apt-get update && apt-get install -y --no-install-recommends \
autoconf \
    automake \
    cryptsetup \
    fuse2fs \
    git \
    fuse \
    libfuse-dev \
    libglib2.0-dev \
    libseccomp-dev \
    libtool \
    pkg-config \
    runc \
    squashfs-tools \
    squashfs-tools-ng \
    uidmap \
    wget \
    zlib1g-dev \
    curl


ENV VERSION=1.21.9 OS=linux ARCH=amd64


RUN wget --no-check-certificate -O /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz https://dl.google.com/go/go${VERSION}.${OS}-${ARCH}.tar.gz && \
sudo tar -C /usr/local -xzf /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz

RUN echo 'export GOPATH=${HOME}/go' >> ~/.bashrc && \
echo 'export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin' >> ~/.bashrc 
# source ~/.bashrc
ENV GOPATH=${HOME}/go
ENV PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin

RUN curl -sfL https://install.goreleaser.com/github.com/golangci/golangci-lint.sh | \
sh -s -- -b $(go env GOPATH)/bin v1.21.0


RUN sudo apt-get install apt-transport-https ca-certificates -y
RUN sudo update-ca-certificates


RUN mkdir -p ${GOPATH}/src/github.com/sylabs && \
cd ${GOPATH}/src/github.com/sylabs && \
git clone --recurse-submodules https://github.com/sylabs/singularity.git && \
cd singularity
WORKDIR ${GOPATH}/src/github.com/sylabs/singularity
RUN git checkout v4.1.2

RUN apt-get install make -y
RUN cd ${GOPATH}/src/github.com/sylabs/singularity && \
./mconfig && \
cd ./builddir && \
make && \
sudo make install

RUN singularity version

RUN export TZ=Europe/Minsk && \
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# ********************************************************
# * Anything else you want to do like clean up goes here *
# ********************************************************

# [Optional] Set the default user. Omit if you want to keep the default as root.
USER $USERNAME
# add user to sudo group
RUN sudo usermod -aG sudo $USERNAME

# ------------------- install OpenFold and ESM2 -------------------
ENV PATH="/home/vscode/.local/bin:${PATH}"
WORKDIR /home/vscode


RUN singularity version

ENTRYPOINT ["/bin/bash"]
