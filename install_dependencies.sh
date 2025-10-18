#! /bin/bash
# reset the terminal
source ~/.bashrc
echo "Installing Dependencies"
# pythonversion="miniconda3-3.9-4.10.3"
pythonversion="miniconda3-4.7.12"
poetryversion="1.1.13"
echo "Check if python version is correct or not. Current python version is: $pythonversion"
echo "Check if poetry version is correct or not. Current poetry version is: $poetryversion"

if command -v pyenv > /dev/null 2>&1; then
    echo "pyenv exists"
else
    echo "pyenv does not exist. Installing pyenv."
    curl https://pyenv.run | bash

    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    echo 'eval "$(pyenv init -)"' >> ~/.bashrc

    $SHELL
fi

source ~/.bashrc

# check if local dependencies for ESMDispred already exist
if [ ! -d ".venv" ]; then
    echo "Installing ESMDispred dependencies"

    export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
    echo "Installing python version: $pythonversion"
    pyenv install -s $pythonversion
    pyenv local $pythonversion

    # Create local poetry environment
    echo "Creating local environment"
    rm -rf .venv
    rm -rf poetry.lock
    python3 -m venv .venv
    echo "Installing pip and setuptools"
    ./.venv/bin/pip install -U pip setuptools
    ./.venv/bin/pip install poetry==$poetryversion
    POETRY_VIRTUALENVS_IN_PROJECT="true"

    # Install Poetry Dependencies
    ./.venv/bin/poetry

    # Test Installation
    ./.venv/bin/poetry run python --version
    echo "Installing dependencies in poetry"
    ./.venv/bin/poetry install --no-root
else
    echo "ESMDispred dependencies already installed"
fi

# keep this as-is:
ln -fs "$(pwd)/.venv" "$(pwd)/tools/Dispredict3.0/.venv"

################################################################################
# ADDITIONAL ENVIRONMENT: create a separate conda env (Python 3.9) alongside .venv
################################################################################

set -euo pipefail

PYENV_MINICONDA="${pythonversion}"         # miniconda3-4.7.12
CONDA_ENV_NAME="py39"
PROJECT_ROOT="$(pwd)"
DISPRED_TOOL_DIR="$PROJECT_ROOT/tools/Dispredict3.0"
# Full path to the conda env directory
CONDA_ENV_PATH="$HOME/.pyenv/versions/${PYENV_MINICONDA}/envs/${CONDA_ENV_NAME}"

echo "----- Setting up additional conda environment: ${CONDA_ENV_NAME} (Python 3.9) -----"

# Ensure pyenv miniconda exists
if ! pyenv versions --bare | grep -qx "${PYENV_MINICONDA}"; then
  echo "Installing ${PYENV_MINICONDA} via pyenv..."
  pyenv install "${PYENV_MINICONDA}"
fi

# Ensure conda is on PATH for this shell
eval "$(pyenv init -)"
pyenv shell "${PYENV_MINICONDA}"

CONDA_BIN="$HOME/.pyenv/versions/${PYENV_MINICONDA}/bin/conda"
# Initialize conda shell hook
eval "$($HOME/.pyenv/versions/${PYENV_MINICONDA}/bin/conda shell.bash hook)"

# Create env if missing
if ! "$CONDA_BIN" env list | awk '{print $1}' | grep -qx "${CONDA_ENV_NAME}"; then
  echo "Creating conda env '${CONDA_ENV_NAME}'..."
  "$CONDA_BIN" create -y -n "${CONDA_ENV_NAME}" python=3.9
else
  echo "Conda env '${CONDA_ENV_NAME}' already exists."
fi

# (Optional) install requirements into the conda env, but do not touch your .venv
conda activate "${CONDA_ENV_NAME}"
if [[ -f "requirements.txt" ]]; then
  echo "Installing requirements.txt into conda env '${CONDA_ENV_NAME}'..."
  pip install --upgrade pip setuptools wheel
  pip install -r requirements.txt
else
  echo "No requirements.txt found; skipping conda-env pip install."
fi
conda deactivate

# Create helpful symlinks to the conda env (without disturbing your existing .venv)
# Local link so scripts can explicitly use the conda env if desired:
ln -sfn "${CONDA_ENV_PATH}" "${PROJECT_ROOT}/.venv_py39"

# Also link under tools for Dispredict3.0
if [[ -d "${DISPRED_TOOL_DIR}" ]]; then
  ln -sfn "${CONDA_ENV_PATH}" "${DISPRED_TOOL_DIR}/.venv_py39"
fi

echo "----- Additional conda environment ready -----"
echo "Activate via:   conda activate ${CONDA_ENV_NAME}"
echo "Or use:         $(pwd)/.venv_py39/bin/python"
