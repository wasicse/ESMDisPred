#! /bin/bash
# Works in local, Docker (root or --user), and Singularity environments.
# Safe to call from any working directory.
source ~/.bashrc 2>/dev/null || true

set -euo pipefail

echo "Installing ESMDisPred Dependencies"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISPRED_TOOL_DIR="$PROJECT_ROOT/tools/Dispredict3.0"
cd "$PROJECT_ROOT"

# ============================================================
# 1. Install UV if not present
#    Write to /usr/local/bin when writable (containers built as
#    root) so that non-root --user Docker runs can still find it.
#    Fall back to the user-local install otherwise.
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
# 2. System dependency: libidn.so.11
#    The bundled psiblast binary requires libidn.so.11 but
#    modern distros only ship libidn.so.12. Create a symlink
#    if missing.
# ============================================================
if ! ldconfig -p 2>/dev/null | grep -q "libidn\.so\.11"; then
    libpath=$(find /usr/lib /lib -name "libidn.so.12*" 2>/dev/null | grep -v '\.12\.' | head -1)
    if [ -z "$libpath" ]; then
        libpath=$(find /usr/lib /lib -name "libidn.so.12*" 2>/dev/null | head -1)
    fi
    if [ -n "$libpath" ]; then
        target="$(dirname "$libpath")/libidn.so.11"
        echo "Creating libidn.so.11 symlink: $libpath → $target"
        if [ -w "$(dirname "$libpath")" ]; then
            ln -fs "$libpath" "$target"
        else
            sudo ln -fs "$libpath" "$target" 2>/dev/null || \
                echo "  (skipping system symlink — sudo unavailable; lib/libidn.so.11 in project root used instead)"
        fi
        ldconfig 2>/dev/null || sudo ldconfig 2>/dev/null || true
    else
        echo "WARNING: libidn.so.12 not found — psiblast (DisPredict3.0) may fail."
        echo "         Install it with: sudo apt-get install libidn12 libidn11"
    fi
fi

# ============================================================
# 3. Create a single virtual environment for all scripts:
#      run_ESM2.py              (fair-esm, torch)
#      run_ESMDisPred.py        (lightgbm, scikit-learn)
#      transformer_Inference.py (torch >= 2.3.1, joblib)
#      Disnet.py                (tensorflow, keras)
# ============================================================
if [ ! -d ".venv" ]; then
    echo "Creating virtual environment (.venv)..."
    uv venv .venv --python 3.10
fi

echo "Installing/updating dependencies from pyproject.toml..."
uv sync --no-install-project

# Symlink so tools/Dispredict3.0 shares the same env
ln -fs "$PROJECT_ROOT/.venv" "$DISPRED_TOOL_DIR/.venv"

echo ""
echo "All dependencies installed."
echo "  Python: $PROJECT_ROOT/.venv/bin/python"
