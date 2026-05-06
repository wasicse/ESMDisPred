# Full self-contained build — no longer depends on a pre-built base image.
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

ENV ESMpath=/opt/ESMDisPred
ENV TORCH_HOME=${ESMpath}/largeModels

WORKDIR ${ESMpath}

# Clone repo and install Python dependencies
RUN git clone https://github.com/wasicse/ESMDisPred.git . && \
    chmod -R 755 . && \
    ./install_dependencies.sh

# Dry run to validate the pipeline end-to-end at build time
RUN ./run_ESMDisPred.sh 1

ENTRYPOINT ["/bin/bash"]
