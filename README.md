# **ESMDisPred**

**ESMDisPred**: A Structure-Aware CNN–Transformer Framework for Intrinsically Disordered Protein (IDP) Prediction.

---

###  Overview

**ESMDisPred** is a deep learning framework that integrates convolutional and Transformer-based architectures to predict intrinsically disordered regions in proteins. By combining sequence embeddings, evolutionary features, and structural information, ESMDisPred achieves high predictive accuracy and generalization across diverse protein families.

---

###  Model Variants

- **ESMDisPred-1**  
  Utilizes sequence-based features from *DisPredict3.0* and *ESM-1* embeddings.

- **ESMDisPred-2**  
  Extends ESMDisPred-1 by incorporating *ESM-2* embeddings, providing richer contextual protein representations.

- **ESMDisPred-2PDB**  
  Builds upon ESMDisPred-2 by integrating *structural-related features* derived from **PDB** data, enhancing structural context awareness.

- **ESMDisPred-DNN**  
  A comprehensive **CNN–Transformer hybrid** model trained using all feature types from *DisPredict3.0*, *ESM-1*, *ESM-2*, and **PDB-derived structural descriptors**.  
  This variant captures both **local residue patterns (via CNNs)** and **long-range dependencies (via Transformers)**, resulting in superior predictive performance.



---

##  Requirements

* **OS**: Ubuntu 20.04 (tested)
* **Python**: via **pyenv** (recommended). Python 3.9–3.10 typically works best with PyTorch.
* **Hardware**: CPU works; **CUDA GPU** strongly recommended for speed (CUDA 11+).
* **Disk**: ≥ 20 GB free (models + features cache).
* **Tools (optional)**: Docker 24+ or Singularity 3.9+.

> **Tip**: If you plan to run ESM models on GPU, ensure `nvidia-driver`, `nvidia-container-toolkit` (for Docker), and a CUDA-enabled PyTorch build are available.

---

##  Install & Data

```bash
# 1) Get the code
git clone https://github.com/wasicse/ESMDisPred.git
cd ESMDisPred

# 2) Download pre-trained model bundles (large)
./run_downloadLargeModels.sh
```

Dataset examples are under `dataset/`. A demo FASTA is provided at `example/sample.fasta`.

---

##  Quickstart (Local OS)

### A) Install Dependencies (one command)

```bash
# from repo root
./install_dependencies.sh
```

The script will set up Python, packages, and expected folders (including `largeModels/`).

### B) Run a Prediction

```bash
# from repo root
./run_ESMDisPred.sh "$(pwd)/example/sample.fasta" outputs
```

* Input: path to a **FASTA** file (may contain one or more sequences)
* Output: results in the `outputs/` directory

---

##  Run with Docker

You can **build** the image or **pull** it from the registry.

### Option 1: Build from source

```bash
docker build -t wasicse/esmdispred https://github.com/wasicse/ESMDisPred.git#master
```

### Option 2: Pull prebuilt image

```bash
docker pull wasicse/esmdispred:latest
```

### Run

The helper script mounts your input FASTA, `largeModels/`, and `outputs/` into the container:

```bash
# create and run the containerized job
./run_ESMDisPred_Docker.sh "$(pwd)/example/sample.fasta" outputs

# (advanced) call the inner script directly after container creation
./run_ESMDisPred.sh "$(pwd)/example/sample.fasta" outputs
```

> **GPU**: If you have NVIDIA GPUs, ensure `nvidia-container-toolkit` is installed and the script uses `--gpus all`. Otherwise, modify the script or run:
>
> ```bash
> docker run --rm --gpus all -v "$(pwd)":/opt/ESMDisPred -w /opt/ESMDisPred wasicse/esmdispred:latest \
>   ./run_ESMDisPred.sh /opt/ESMDisPred/example/sample.fasta /opt/ESMDisPred/outputs
> ```

---

##  Run with Singularity

### Build from definition

```bash
sudo singularity build ESMDispS.sif ESMDispS.def

sudo singularity run --writable-tmpfs \
  -B "$(pwd)/example/sample.fasta:/opt/ESMDisPred/example/sample.fasta" \
  -B "$(pwd)/largeModels:/opt/ESMDisPred/largeModels" \
  -B "$(pwd)/outputs:/opt/ESMDisPred/outputs:rw" \
  ESMDispS.sif

cd /opt/ESMDisPred && ./run_ESMDisPred.sh "$(pwd)/example/sample.fasta" outputs
```

### Build from Docker image

```bash
singularity pull esmdispred.sif docker://wasicse/esmdispred:latest

sudo singularity run --writable-tmpfs \
  -B "$(pwd)/example/sample.fasta:/opt/ESMDisPred/example/sample.fasta" \
  -B "$(pwd)/largeModels:/opt/ESMDisPred/largeModels" \
  -B "$(pwd)/outputs:/opt/ESMDisPred/outputs:rw" \
  esmdispred.sif

cd /opt/ESMDisPred && ./run_ESMDisPred.sh "$(pwd)/example/sample.fasta" outputs
```

---

##  Output

Inside `outputs/` you’ll find:

* **`PROTEINID.caid`** — per-residue disorder probabilities (one file per sequence), tab- or space-delimited.
* **`timings.csv`** — wall-clock timings per stage/model.
* Subfolders by model variant (e.g., `ESMDisPred-1/`, `ESMDisPred-2/`, …) when applicable.

**File format (`*.caid`)**

```
# Example (columns may include: residue_index, residue, probability)
1   M   0.034
2   A   0.071
...
```

---


##  Citation

If you use **ESMDisPred**, please cite:

1. Md Wasi Ul Kabir, and Md Tamjidul Hoque. “DisPredict3.0: Prediction of Intrinsically Disordered Regions/Proteins Using Protein Language Model.” *Applied Mathematics and Computation* 472 (July 2024): 128630. [https://doi.org/10.1016/j.amc.2024.128630](https://doi.org/10.1016/j.amc.2024.128630).
2. Hu, Gang, et al. “FlDPnn: Accurate Intrinsic Disorder Prediction with Putative Propensities of Disorder Functions.” *Nature Communications* 12 (2021): 4438. [https://doi.org/10.1038/s41467-021-24773-7](https://doi.org/10.1038/s41467-021-24773-7).
3. Rives, Alexander, et al. “Biological Structure and Function Emerge from Scaling Unsupervised Learning to 250 Million Protein Sequences.” *PNAS* 118, no. 15 (2021): e2016239118. [https://doi.org/10.1073/pnas.2016239118](https://doi.org/10.1073/pnas.2016239118).
4. Lin, Zeming, et al. “Evolutionary-scale prediction of atomic-level protein structure with a language model.” *Science* 379 (2023): 1123–1130. [https://doi.org/10.1126/science.ade2574](https://doi.org/10.1126/science.ade2574).

> ** BibTeX block**
>
> ```bibtex
> @article{Kabir2024DisPredict3,
>   title={DisPredict3.0: Prediction of Intrinsically Disordered Regions/Proteins Using Protein Language Model},
>   author={Kabir, Md Wasi Ul and Hoque, Md Tamjidul},
>   journal={Applied Mathematics and Computation},
>   volume={472},
>   pages={128630},
>   year={2024},
>   doi={10.1016/j.amc.2024.128630}
> }
> ```

---

## 👥 Authors & Contact

**Md Wasi Ul Kabir**, **Md Tamjidul Hoque**
Questions/Issues: **Md Tamjidul Hoque** — [thoque@uno.edu](mailto:thoque@uno.edu)

---

