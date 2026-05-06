FROM python:3.9-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        make build-essential libssl-dev wget curl git nano openjdk-11-jre \
    && rm -rf /var/lib/apt/lists/*

# Install UV system-wide
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

WORKDIR /opt

RUN git clone https://github.com/wasicse/Dispredict3.0.git && \
    chmod -R 755 /opt/Dispredict3.0

WORKDIR /opt/Dispredict3.0

# Install deps directly — the upstream repo uses Poetry format so uv sync
# cannot read it; we enumerate the packages explicitly instead.
RUN uv venv .venv --python python3.9 && \
    uv pip install --python .venv/bin/python \
        "scikit-learn>=0.23.1" \
        "keras>=2.4.3" \
        "tensorflow>=2.4.1" \
        "pandas>=1.2.2" \
        "fair-esm>=0.4.0" \
        "lightgbm>=3.3.2" \
        "biopython>=1.79" \
        "gdown>=4.4.0" \
        "torch>=1.13.1"

ENTRYPOINT ["/bin/bash"]
