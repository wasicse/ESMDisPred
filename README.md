# ESMDisPred

**ESMDisPred**: A Structure-Aware CNN–Transformer Framework for Intrinsically Disordered Protein (IDP) Prediction.

---

## Overview

ESMDisPred integrates convolutional and Transformer-based architectures to predict intrinsically disordered regions in proteins. By combining sequence embeddings, evolutionary features, and structural information, it achieves high predictive accuracy across diverse protein families.

---

## Model Variants

| Model | Features used |
|---|---|
| **ESMDisPred-1** | DisPredict3.0 + ESM-1 embeddings |
| **ESMDisPred-2** | DisPredict3.0 + ESM-1 + ESM-2 embeddings |
| **ESMDisPred-2PDB** | DisPredict3.0 + ESM-1 + ESM-2 + PDB structural features |
| **ESMDisPred-DNN** | CNN–Transformer hybrid trained on all feature types |

---

## Requirements

| Requirement | Notes |
|---|---|
| OS | Linux (Ubuntu 20.04+ tested); macOS works locally |
| Python | 3.10 (managed automatically by UV) |
| Disk | ≥ 20 GB free (models + feature cache) |
| Hardware | CPU works; CUDA GPU strongly recommended for speed |
| Docker | 24+ (for Docker path) |
| Singularity | 3.9+ (for HPC path) |

> **GPU note**: for CUDA-accelerated inference, ensure `nvidia-driver` and (for Docker) `nvidia-container-toolkit` are installed, and pass `--gpus all` to `docker run`.

---

## Platform Quickstart

Pick the platform that matches your environment and follow only that section.

- [Local (bare metal)](#1-local-bare-metal)
- [Docker](#2-docker)
- [Singularity (HPC)](#3-singularity-hpc)

---

## 1. Local (bare metal)

### Step 1 — Clone and install

```bash
git clone https://github.com/wasicse/ESMDisPred.git
cd ESMDisPred

# Installs UV if needed, creates .venv, and installs all Python deps
./install_dependencies.sh
```

`install_dependencies.sh` uses [UV](https://docs.astral.sh/uv/) as the package manager. UV is installed automatically if not already present — no manual Python or pip setup required.

### Step 2 — Download pre-trained models

```bash
./run_downloadLargeModels.sh
```

### Step 3 — Run a prediction

```bash
# Interactive — prompts for model selection
./run_ESMDisPred.sh "$(pwd)/example/sample.fasta" outputs

# Non-interactive — pass model as third argument
./run_ESMDisPred.sh "$(pwd)/example/sample.fasta" outputs 1        # ESMDisPred-1
./run_ESMDisPred.sh "$(pwd)/example/sample.fasta" outputs 4        # ESMDisPred-DNN
./run_ESMDisPred.sh "$(pwd)/example/sample.fasta" outputs all      # all models
```

---

## 2. Docker

### Option A — Pull the prebuilt image (fastest)

```bash
docker pull wasicse/esmdispred:latest
```

### Option B — Build from source

```bash
git clone https://github.com/wasicse/ESMDisPred.git
cd ESMDisPred
docker build -t wasicse/esmdispred:latest .
```

### Run

The helper script mounts your input FASTA, large models, and output directory into the container:

```bash
git clone https://github.com/wasicse/ESMDisPred.git   # if not already cloned
cd ESMDisPred

# Download large models to the local largeModels/ folder first
./run_downloadLargeModels.sh

# Interactive mode
./run_ESMDisPred_Docker.sh "$(pwd)/example/sample.fasta" outputs

# Non-interactive mode
./run_ESMDisPred_Docker.sh "$(pwd)/example/sample.fasta" outputs 3
./run_ESMDisPred_Docker.sh "$(pwd)/example/sample.fasta" outputs ESMDisPred-DNN
./run_ESMDisPred_Docker.sh "$(pwd)/example/sample.fasta" outputs all
```

**Model options (3rd argument):**

| Value | Description |
|---|---|
| `1` / `ESMDisPred-1` | DisPredict3.0 + ESM1 |
| `2` / `ESMDisPred-2` | DisPredict3.0 + ESM1 + ESM2 |
| `3` / `ESMDisPred-2PDB` | DisPredict3.0 + ESM1 + ESM2 + PDB |
| `4` / `ESMDisPred-DNN` | CNN–Transformer hybrid |
| `5` / `all` | Run all models |

---

## 3. Singularity / Apptainer (HPC)

HPC clusters typically have Singularity or Apptainer instead of Docker. The helper script `run_ESMDisPred_Singularity.sh` handles both automatically and builds the `.sif` image from the published Docker image on first run — no root access required.

### Step 1 — Clone the repo

```bash
git clone https://github.com/wasicse/ESMDisPred.git
cd ESMDisPred
```

### Step 2 — Download large models

```bash
./run_downloadLargeModels.sh
```

### Step 3 — Run a prediction

```bash
# Non-interactive (recommended on HPC)
./run_ESMDisPred_Singularity.sh "$(pwd)/example/sample.fasta" outputs 4        # ESMDisPred-DNN
./run_ESMDisPred_Singularity.sh "$(pwd)/example/sample.fasta" outputs 3        # ESMDisPred-2PDB
./run_ESMDisPred_Singularity.sh "$(pwd)/example/sample.fasta" outputs all      # all models

# Interactive (prompts for model selection)
./run_ESMDisPred_Singularity.sh "$(pwd)/example/sample.fasta" outputs
```

On first run the script pulls `wasicse/esmdispred:latest` from Docker Hub and saves it as `esmdispred.sif` (~10 GB). Subsequent runs reuse the cached `.sif`.

> **Custom .sif path** — pass it as the optional 4th argument if you want to store the image elsewhere (e.g. a shared project directory on the cluster):
> ```bash
> ./run_ESMDisPred_Singularity.sh input.fasta outputs 4 /scratch/shared/esmdispred.sif
> ```

> **Module load** — if `apptainer`/`singularity` is not in PATH by default, load it first:
> ```bash
> module load apptainer   # or: module load singularity
> ```

**Interactive shell inside the container:**

```bash
singularity shell \
  -B "$(pwd)/largeModels:/opt/ESMDisPred/largeModels" \
  -B "$(pwd)/outputs:/opt/ESMDisPred/outputs" \
  esmdispred.sif

# inside the container:
cd /opt/ESMDisPred
./run_ESMDisPred.sh example/sample.fasta outputs 4
```

---

## Output

Results are written to your output directory:

| File | Description |
|---|---|
| `<PROTEINID>.caid` | Per-residue disorder probabilities |
| `esmdispred.log` | Full run log with timings |

**`.caid` format** (tab-separated):

```
1    M    0.034
2    A    0.071
3    K    0.183
...
```

Columns: residue index, amino acid, disorder probability (0 = ordered, 1 = disordered).

---

## Citation

If you use ESMDisPred, please cite:

1. Md Wasi Ul Kabir, Ayon Dey, Farzeen Nafees, and Md Tamjidul Hoque. "ESMDisPred: A Structure-Aware CNN-Transformer Architecture for Intrinsically Disordered Protein Prediction." *bioRxiv* (2026). https://doi.org/10.64898/2026.01.22.701204

2. Md Wasi Ul Kabir, and Md Tamjidul Hoque. "DisPredict3.0: Prediction of Intrinsically Disordered Regions/Proteins Using Protein Language Model." *Applied Mathematics and Computation* 472 (July 2024): 128630. https://doi.org/10.1016/j.amc.2024.128630

<details>
<summary>BibTeX</summary>

```bibtex
@article{Kabir2026ESMDisPred,
  author    = {Kabir, Md Wasi Ul and Dey, Ayon and Nafees, Farzeen and Hoque, Md Tamjidul},
  title     = {ESMDisPred: A Structure-Aware CNN-Transformer Architecture for Intrinsically Disordered Protein Prediction},
  year      = {2026},
  doi       = {10.64898/2026.01.22.701204},
  journal   = {bioRxiv}
}

@article{Kabir2024DisPredict3,
  author    = {Kabir, Md Wasi Ul and Hoque, Md Tamjidul},
  title     = {DisPredict3.0: Prediction of Intrinsically Disordered Regions/Proteins Using Protein Language Model},
  journal   = {Applied Mathematics and Computation},
  volume    = {472},
  pages     = {128630},
  year      = {2024},
  doi       = {10.1016/j.amc.2024.128630}
}
```

</details>

---

## Authors & Contact

**Md Wasi Ul Kabir**, **Md Tamjidul Hoque**  
Questions / Issues: Md Tamjidul Hoque — [thoque@uno.edu](mailto:thoque@uno.edu)
