#!/usr/bin/env bash
set -euo pipefail


# 1) Set your token once (or rely on interactive login)
export HF_TOKEN=

# 2) Run (fast multipart upload path)
./hf_upload_dataset.sh /home/mkabir3/Research/40_CAID3/12_FinalVersion/ESMDisPred/largeModels wasicse/ESMDisPred

# Optional knobs:
#   PRIVATE=true           # create private dataset
#   PARALLEL=8             # more parallelism
#   USE_TRANSFER=false     # disable hf_transfer
#   USE_GIT=true           # also do a Git+LFS push afterwards
#   BRANCH=dev             # push to a different branch



# =======================
# Config (env or args)
# =======================
REPO_ID="${REPO_ID:-${2:-}}";             # e.g. username/my-big-dataset
DATA_DIR="${DATA_DIR:-${1:-}}";           # local folder with your data
BRANCH="${BRANCH:-main}"                  # target branch on the Hub
MSG="${MSG:-"Add/Update dataset"}"
PRIVATE="${PRIVATE:-false}"               # true|false
PARALLEL="${PARALLEL:-4}"                 # parallel uploads
TOKEN="${HF_TOKEN:-${HF_TOKEN:-}}"        # set export HF_TOKEN=xxx or login
USE_GIT="${USE_GIT:-false}"               # set true to push via Git+LFS as fallback
USE_TRANSFER="${USE_TRANSFER:-true}"      # install & enable hf_transfer for speed

# =======================
# Checks
# =======================
if [[ -z "${DATA_DIR}" || -z "${REPO_ID}" ]]; then
  echo "Usage: $0 <DATA_DIR> <REPO_ID>   (e.g. ./hf_upload_dataset.sh ./data me/my-ds)"
  echo "You can also set env vars: DATA_DIR, REPO_ID, BRANCH, MSG, PRIVATE, PARALLEL, HF_TOKEN, USE_GIT"
  exit 1
fi
if [[ ! -d "$DATA_DIR" ]]; then
  echo "DATA_DIR '$DATA_DIR' does not exist or is not a directory"; exit 1
fi

# =======================
# Tools
# =======================
python3 - <<'PY' || { echo "Installing huggingface_hub CLI..."; pip install -U "huggingface_hub[cli]"; }
import pkgutil, sys
sys.exit(0 if pkgutil.find_loader("huggingface_hub") else 1)
PY

if [[ "${USE_TRANSFER}" == "true" ]]; then
  python3 - <<'PY' || { echo "Installing hf_transfer for faster uploads..."; pip install -U hf_transfer; }
import pkgutil, sys
sys.exit(0 if pkgutil.find_loader("hf_transfer") else 1)
PY
  export HF_HUB_ENABLE_HF_TRANSFER=1
fi

# =======================
# Auth
# =======================
if [[ -n "${TOKEN}" ]]; then
  huggingface-cli login --token "$TOKEN" --add-to-git-credential || true
else
  # Will open a prompt if not already logged in
  huggingface-cli whoami >/dev/null 2>&1 || huggingface-cli login
fi

# =======================
# Create repo if needed
# =======================
echo "Ensuring dataset repo ${REPO_ID} exists (private=${PRIVATE})..."
huggingface-cli repo create "${REPO_ID}" \
  --repo-type dataset \
  $( [[ "${PRIVATE}" == "true" ]] && echo "--private" ) \
  --yes >/dev/null || true

# =======================
# Fast path: CLI multipart upload
# - Resumable
# - Parallel
# - No local Git history
# =======================
echo "Uploading ${DATA_DIR} to hf://datasets/${REPO_ID}@${BRANCH}"
echo "Message: ${MSG}"

# Create the branch if it doesn't exist
huggingface-cli upload "${REPO_ID}" \
  --repo-type dataset \
  --branch "${BRANCH}" \
  --commit-message "${MSG} (create branch if missing)" \
  --allow-create \
  --make-commit \
  --quiet \
  "/dev/null" ":" 2>/dev/null || true

# Upload directory contents in parallel (resumable, idempotent)
# Notes:
# - The trailing ":" means "same relative path in repo".
# - If interrupted, just run the script again; it resumes.
# - Adjust PARALLEL for your network.
export HF_UPLOAD_REPO_ID="${REPO_ID}"
export HF_UPLOAD_BRANCH="${BRANCH}"

# Find all files and upload them one by one with xargs -P
# (This avoids a single monolithic commit; but still keeps atomic path updates.)
find "${DATA_DIR}" -type f -print0 | \
  xargs -0 -n 1 -P "${PARALLEL}" -I{} \
  huggingface-cli upload "${REPO_ID}" "{}" ":" \
    --repo-type dataset \
    --branch "${BRANCH}" \
    --commit-message "${MSG}" \
    --quiet

echo "✓ Upload complete."

# =======================
# Optional: Git + LFS push (fallback)
# Pros: single commit/tree view like a repo
# Cons: slower for many very-large files; still fine for most cases
# Enable with USE_GIT=true
# =======================
if [[ "${USE_GIT}" == "true" ]]; then
  echo "Running Git+LFS push fallback..."
  command -v git >/dev/null 2>&1 || { echo "Installing git & git-lfs is required for USE_GIT=true"; exit 1; }
  command -v git-lfs >/dev/null 2>&1 || { echo "Installing git-lfs..."; sudo apt-get update && sudo apt-get install -y git-lfs || true; git lfs install; }

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  huggingface-cli repo clone "${REPO_ID}" "${TMP_DIR}" --repo-type dataset
  cd "${TMP_DIR}"
  git checkout -B "${BRANCH}"

  # Track common large formats via LFS (edit as needed)
  git lfs track "*.parquet" "*.h5" "*.hdf5" "*.npz" "*.npy" "*.pt" "*.bin" "*.tar" "*.gz" "*.xz" "*.zip" "*.zst" "*.pkl"
  git add .gitattributes

  rsync -a --delete "${DATA_DIR}/" "${TMP_DIR}/"
  git add -A
  if ! git diff --cached --quiet; then
    git commit -m "${MSG}"
    GIT_ASKPASS=/bin/echo git push -u origin "${BRANCH}"
    echo "✓ Git+LFS push complete."
  else
    echo "No changes to commit (Git path)."
  fi
fi

echo "All done. View at: https://huggingface.co/datasets/${REPO_ID}/tree/${BRANCH}"
