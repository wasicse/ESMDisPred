# %%
# Author : Md Wasi Ul Kabir  

import torch
import esm
import pathlib 
# import joblib
import numpy as np
import warnings
from Bio import SeqIO
# import gdown
# import subprocess
from optparse import OptionParser
import os
import random
from pathlib import Path

import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from preprocess import sanitize_sequence
warnings.filterwarnings("ignore")
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  
np.set_printoptions(precision=3)

# Set a seed value: 
seed_value= 2515  
os.environ['PYTHONHASHSEED']=str(seed_value) 
random.seed(seed_value) 
np.random.seed(seed_value) 

# Ensure TORCH_HOME is set correctly
if 'TORCH_HOME' not in os.environ:
    os.environ['TORCH_HOME'] = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'largeModels')

# Also set torch hub directory
os.environ['TORCH_HUB'] = os.environ['TORCH_HOME']

def loadPrecomputedEmbeddings(fasta_filepath, embeddings_dir, output_path):
    """Load pre-computed ESM2 embeddings provided by CAID (.npy or .h5 per protein)."""
    print("\n","#"*40,"Loading pre-computed ESM2 embeddings...","#"*40, "\n")
    for record in SeqIO.parse(fasta_filepath, "fasta"):
        pid = record.id.strip()
        out_csv = output_path + pid + ".csv"
        if os.path.exists(out_csv):
            print(f"Already exists, skipping: {pid}")
            continue

        npy_path = os.path.join(embeddings_dir, pid + ".npy")
        h5_path  = os.path.join(embeddings_dir, pid + ".h5")

        if os.path.exists(npy_path):
            emb = np.load(npy_path)
            print(f"Loaded .npy for {pid}: shape={emb.shape}")
        elif os.path.exists(h5_path):
            import h5py
            with h5py.File(h5_path, "r") as hf:
                key = pid if pid in hf else list(hf.keys())[0]
                emb = hf[key][:]
            print(f"Loaded .h5 for {pid}: shape={emb.shape}")
        else:
            print(f"WARNING: no embedding found for {pid} in {embeddings_dir} — skipping")
            continue

        np.savetxt(out_csv, emb, delimiter=",")
        print(f"Saved: {out_csv}")


def _save_repr(output_path, pid, arr):
    np.save(output_path + pid + ".npy", arr)

def _run_batch(model, batch_converter, alphabet, device, layern, batch, output_path):
    batch_labels, batch_strs, batch_tokens = batch_converter(batch)
    batch_tokens = batch_tokens.to(device)
    batch_lens = (batch_tokens != alphabet.padding_idx).sum(1)
    with torch.no_grad():
        results = model(batch_tokens, repr_layers=[layern], return_contacts=False)
    token_representations = results["representations"][layern]
    for j, (pid, _) in enumerate(batch):
        seq_len = int(batch_lens[j].item()) - 1
        arr = token_representations[j, 1:seq_len].cpu().numpy()
        _save_repr(output_path, pid, arr)
        print(f"  {pid}: shape={arr.shape}")

def extractFeatures(fasta_filepath, output_path, batch_size=4):
    print("\n","#"*40,"Extracting features from ESM-2...","#"*40, "\n")

    ESM2_MIN_FREE_GB = 2.0
    if torch.cuda.is_available():
        free_gb = torch.cuda.mem_get_info()[0] / (1024 ** 3)
        device = torch.device("cuda" if free_gb >= ESM2_MIN_FREE_GB else "cpu")
    else:
        device = torch.device("cpu")
    print("Using device:", device)

    model, alphabet = esm.pretrained.esm2_t33_650M_UR50D()
    try:
        model = model.to(device)
    except torch.cuda.OutOfMemoryError:
        print("WARNING: GPU OOM — retrying on CPU")
        device = torch.device("cpu")
        model = model.to(device)
    batch_converter = alphabet.get_batch_converter()
    model.eval()
    layern = 33

    # Collect sequences not yet cached (.npy preferred, .csv accepted as legacy)
    pending = []
    for record in SeqIO.parse(fasta_filepath, "fasta"):
        pid = record.id.strip()
        if os.path.exists(output_path + pid + ".npy") or os.path.exists(output_path + pid + ".csv"):
            print(f"  {pid}: cached, skipping")
            continue
        pending.append((pid, sanitize_sequence(str(record.seq))))

    if not pending:
        print("All ESM2 features already cached.")
        return

    # Sort by length — minimises padding within each batch
    pending.sort(key=lambda x: len(x[1]))
    print(f"Extracting features for {len(pending)} sequence(s) with batch_size={batch_size}...")

    for i in range(0, len(pending), batch_size):
        batch = pending[i:i + batch_size]
        pids = [p for p, _ in batch]
        print(f"Batch {i//batch_size + 1}: {pids}")
        try:
            _run_batch(model, batch_converter, alphabet, device, layern, batch, output_path)
        except torch.cuda.OutOfMemoryError:
            print(f"  GPU OOM on batch size {len(batch)} — retrying one-by-one")
            torch.cuda.empty_cache()
            for item in batch:
                try:
                    _run_batch(model, batch_converter, alphabet, device, layern, [item], output_path)
                except torch.cuda.OutOfMemoryError:
                    print(f"  GPU OOM on single sequence {item[0]} — switching to CPU")
                    torch.cuda.empty_cache()
                    model_cpu = model.to("cpu")
                    _run_batch(model_cpu, batch_converter, alphabet, "cpu", layern, [item], output_path)
                    model.to(device)

    print("Feature Extraction Complete.")       

if __name__ == "__main__":  
    parent_path = str(Path(__file__).resolve().parents[1])
    # print("Parent Dir",parent_path)

    parser = OptionParser()
    parser.add_option("-f", "--fasta_filepath", dest="fasta_filepath", help="Path to input fasta.", default=parent_path+'/example/sample.fasta')
    parser.add_option("-o", "--output_path", dest="output_path", help="Path to output.", default=parent_path+'/output/')
    parser.add_option("-e", "--embeddings_dir", dest="embeddings_dir", help="Directory of pre-computed ESM2 embeddings (.npy or .h5 per protein). Skips running ESM2 if provided.", default=None)
    parser.add_option("-b", "--batch_size", dest="batch_size", type="int", help="Number of sequences per ESM2 forward pass (default 4). Reduce if GPU OOM.", default=4)

    (options, args) = parser.parse_args()

    fasta_filepath=options.fasta_filepath
    output_path=options.output_path

    workspace=output_path
    pathlib.Path(workspace).mkdir(parents=True, exist_ok=True)

    if options.embeddings_dir:
        loadPrecomputedEmbeddings(fasta_filepath, options.embeddings_dir, output_path)
    else:
        extractFeatures(fasta_filepath, output_path, batch_size=options.batch_size)
    



