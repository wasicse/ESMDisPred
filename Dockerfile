FROM debian:buster-slim
RUN mkdir -p /usr/share/man/man1 /usr/share/man/man2

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
RUN apt-get update && apt-get install -y --no-install-recommends make build-essential libssl-dev  wget curl llvm libidn11 openjdk-11-jre git nano tcsh sudo  && apt-get clean




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







# use gdown to download above files from google drive
RUN mkdir -p /home/vscode/.cache/torch/hub/checkpoints
WORKDIR /home/vscode/.cache/torch/hub/checkpoints
# change permission
RUN sudo chmod -R 777 /home/vscode/.cache/torch/hub/checkpoints

WORKDIR /home/vscode

RUN git clone https://github.com/wasicse/ESMDisPred.git

# echo list of directories
RUN  echo .* *

RUN chmod -R 777 /home/vscode/ESMDisPred
WORKDIR "/home/vscode/ESMDisPred"


# RUN git clone --depth=1 https://github.com/pyenv/pyenv.git .pyenv
ENV PYENV_ROOT="/home/vscode/.pyenv" 
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"
RUN echo 'export PYENV_ROOT=/home/vscode/.pyenv' >> ~/.bashrc
RUN echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(pyenv init -)"' >> ~/.bashrc


# install and set up pyenv
RUN bash -c 'set -eo pipefail; curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash'

ENV PYTHON_VERSION=miniconda3-3.9-4.10.3
RUN pyenv install ${PYTHON_VERSION} && \
      pyenv global ${PYTHON_VERSION}

ENV PYTHON_VERSION=miniconda3-4.7.12
RUN pyenv install ${PYTHON_VERSION} 


RUN ./install_dependencies.sh

RUN echo "updated git repository"
RUN git reset --hard HEAD
RUN git pull

ENTRYPOINT ["/bin/bash"]
