#! /bin/bash
# Works in local, Docker, and Singularity environments.
# Safe to call from any working directory.
source ~/.bashrc 2>/dev/null || true

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Installing Dispredict3.0 Dependencies"

# ============================================================
# 1. Install UV if not present
# ============================================================
if ! command -v uv > /dev/null 2>&1; then
    echo "UV not found. Installing UV..."
    if [ -w /usr/local/bin ]; then
        curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh
    else
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    fi
fi

echo "UV version: $(uv --version)"

# ============================================================
# 2. Create virtual environment and install dependencies
# ============================================================
echo "Creating virtual environment (.venv)..."
rm -rf .venv
uv venv .venv --python 3.9

echo "Installing dependencies from pyproject.toml..."
uv sync --no-install-project

echo ""
echo "Dispredict3.0 dependencies installed."
echo "  Python: $SCRIPT_DIR/.venv/bin/python"
