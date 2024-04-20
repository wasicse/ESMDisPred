FROM debian:buster-slim
RUN mkdir -p /usr/share/man/man1 /usr/share/man/man2

RUN apt-get update && \
apt-get install -y --no-install-recommends make build-essential libssl-dev  wget curl llvm libidn11 openjdk-11-jre git nano tcsh sudo 

WORKDIR "/opt"

RUN git clone --depth=1 https://github.com/pyenv/pyenv.git .pyenv
ENV PYENV_ROOT="/opt/.pyenv" 
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"
RUN echo 'export PYENV_ROOT=/opt/.pyenv' >> ~/.bashrc
RUN echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(pyenv init -)"' >> ~/.bashrc

ENV PYTHON_VERSION=miniconda3-3.9-4.10.3
RUN pyenv install ${PYTHON_VERSION} && \
      pyenv global ${PYTHON_VERSION}

ENV PYTHON_VERSION=miniconda3-4.7.12
RUN pyenv install ${PYTHON_VERSION} 

      
RUN git clone https://github.com/wasicse/ESMDisPred.git

WORKDIR "/opt/ESMDisPred"

RUN ./install_dependencies.sh

ENTRYPOINT [ "/bin/bash" ]


