# Base image builder — kept in sync with the root Dockerfile.
FROM python:3.10-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        make build-essential libssl-dev wget curl git nano tcsh \
        openjdk-11-jre libidn11 libidn12 llvm \
    && rm -rf /var/lib/apt/lists/*

# Ensure libidn.so.11 exists — bundled psiblast requires it
RUN libpath=$(find /usr/lib /lib -name "libidn.so.12" 2>/dev/null | head -1) \
    && [ -n "$libpath" ] \
    && ln -fs "$libpath" "$(dirname "$libpath")/libidn.so.11" \
    && ldconfig \
    || true

# Install UV system-wide so non-root --user runs can still find it
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

WORKDIR /opt

RUN git clone https://github.com/wasicse/ESMDisPred.git && \
    chmod -R 755 /opt/ESMDisPred

WORKDIR /opt/ESMDisPred

ENV TORCH_HOME=/opt/ESMDisPred/largeModels

RUN ./install_dependencies.sh

ENTRYPOINT ["/bin/bash"]
