# Full self-contained build — copies local files (no git clone needed).
FROM python:3.10-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        make build-essential libssl-dev wget curl git nano tcsh \
        default-jre libidn12 llvm \
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

# Copy local repo (features/, largeModels/, outputs/ excluded via .dockerignore)
COPY . .

# Recreate symlinks with container-absolute paths.
# COPY carries local host paths (e.g. /home/mkabir3/...); at runtime largeModels/
# is mounted at /opt/ESMDisPred/largeModels so we need that prefix here.
RUN ln -fs /opt/ESMDisPred/largeModels/model.pkl   tools/Dispredict3.0/models/model.pkl && \
    ln -fs /opt/ESMDisPred/largeModels/pca.pkl     tools/Dispredict3.0/models/pca.pkl && \
    ln -fs /opt/ESMDisPred/largeModels/scaler.pkl  tools/Dispredict3.0/models/scaler.pkl && \
    ln -fs /opt/ESMDisPred/largeModels/swissprot.psq \
        tools/Dispredict3.0/tools/fldpnn/programs/blast-2.2.24/db/swissprot.psq && \
    ln -fs /opt/ESMDisPred/largeModels/swissprot.phr \
        tools/Dispredict3.0/tools/fldpnn/programs/blast-2.2.24/db/swissprot.phr && \
    mkdir -p .cache/hub/checkpoints && \
    ln -fs /opt/ESMDisPred/largeModels/esm1b_t33_650M_UR50S.pt \
        .cache/hub/checkpoints/esm1b_t33_650M_UR50S.pt && \
    ln -fs /opt/ESMDisPred/largeModels/esm2_t33_650M_UR50D.pt \
        .cache/hub/checkpoints/esm2_t33_650M_UR50D.pt && \
    ln -fs /opt/ESMDisPred/largeModels/esm1b_t33_650M_UR50S-contact-regression.pt \
        .cache/hub/checkpoints/esm1b_t33_650M_UR50S-contact-regression.pt && \
    ln -fs /opt/ESMDisPred/largeModels/esm2_t33_650M_UR50D-contact-regression.pt \
        .cache/hub/checkpoints/esm2_t33_650M_UR50D-contact-regression.pt && \
    ln -fs /opt/ESMDisPred/largeModels/best.pt models/best.pt

RUN chmod -R 755 . && \
    # Allow non-root Docker users to create temp files in fldpnn (DisoComb.sh, psiblast,
    # Java tools all write relative to their CWD which is the fldpnn directory).
    find tools/Dispredict3.0/tools/fldpnn -type d -exec chmod 777 {} + && \
    ./install_dependencies.sh

# Validate all key imports work with the installed environment
RUN .venv/bin/python -c "\
import torch, esm, sklearn, joblib, lightgbm; \
from Bio import SeqIO; \
import pandas, numpy, scipy; \
print('Python:', __import__('sys').version); \
print('PyTorch:', torch.__version__); \
print('CUDA available:', torch.cuda.is_available()); \
print('All imports OK')"

# Runtime scratch directories. A standalone `docker run --user $(id -u):$(id -g)`
# with no bind mounts must be able to write these, and /opt/ESMDisPred itself is
# root-owned 755. The wrapper scripts bind-mount over them, so this only affects
# direct image use — which is how CAID runs it.
RUN mkdir -p features outputs .config && chmod 777 features outputs .config && chmod -R 777 .cache

ENTRYPOINT ["/bin/bash"]
