#!/usr/bin/env python3
import os, json, math, warnings, time, datetime
import numpy as np
import pandas as pd
import torch
import torch.nn as nn
from Bio import SeqIO
import joblib
from preprocess import preProcess_features, sanitize_sequence

warnings.filterwarnings("ignore")

# ------------------------- Model pieces (match training) -------------------------
class SinusoidalPositionalEncoding(nn.Module):
    def __init__(self, d_model: int, max_len: int = 8192):
        super().__init__()
        pe = torch.zeros(max_len, d_model, dtype=torch.float32)
        pos = torch.arange(0, max_len, dtype=torch.float32).unsqueeze(1)
        div = torch.exp(torch.arange(0, d_model, 2, dtype=torch.float32) * (-math.log(10000.0) / d_model))
        pe[:, 0::2] = torch.sin(pos * div)
        pe[:, 1::2] = torch.cos(pos * div)
        self.register_buffer("pe", pe[None, ...])  # [1, max_len, d_model]

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        T = x.size(1)
        return x + self.pe[:, :T, :]

class LocalConvStem(nn.Module):
    """Depthwise-separable multi-kernel conv stem to capture short/medium motifs."""
    def __init__(self, d_model: int, ks=(5, 9, 15), dropout: float = 0.05):
        super().__init__()
        layers = []
        ch = d_model
        for k in ks:
            pad = k // 2
            layers += [
                nn.Conv1d(ch, ch, kernel_size=k, padding=pad, groups=ch),  # depthwise
                nn.Conv1d(ch, ch, kernel_size=1),                          # pointwise
                nn.GELU(),
            ]
        self.net = nn.Sequential(*layers)
        self.drop = nn.Dropout(dropout)

    def forward(self, x):  # x: [B,T,C]
        x = x.transpose(1, 2)   # -> [B,C,T]
        x = self.net(x)
        x = x.transpose(1, 2)   # -> [B,T,C]
        return self.drop(x)

class TransformerResidueClassifier(nn.Module):
    def __init__(self, input_size: int, d_model: int = 512, nhead: int = 8,
                 num_layers: int = 8, dim_ff: int = 2048, dropout: float = 0.2,
                 input_dropout: float = 0.05, use_stem: bool = True):
        super().__init__()
        self.proj = nn.Linear(input_size, d_model)
        self.input_drop = nn.Dropout(input_dropout)
        self.pos = SinusoidalPositionalEncoding(d_model)
        self.stem = LocalConvStem(d_model, ks=(5, 9, 15), dropout=0.05) if use_stem else None

        layer = nn.TransformerEncoderLayer(
            d_model=d_model, nhead=nhead, dim_feedforward=dim_ff,
            dropout=dropout, batch_first=True, norm_first=True
        )
        self.encoder = nn.TransformerEncoder(layer, num_layers=num_layers)
        self.drop = nn.Dropout(dropout)
        self.fc = nn.Linear(d_model, 1)

    def forward(self, x: torch.Tensor, lengths: torch.Tensor) -> torch.Tensor:
        x = self.input_drop(self.proj(x))
        x = self.pos(x)
        if self.stem is not None:
            x = self.stem(x)
        B, T, _ = x.shape
        idx = torch.arange(T, device=lengths.device).unsqueeze(0).expand(B, T)
        pad_mask = idx >= lengths.view(-1, 1)  # [B,T] bool
        out = self.encoder(x, src_key_padding_mask=pad_mask)
        out = self.drop(out)
        logits = self.fc(out).squeeze(-1)  # [B,T]
        return logits

# ------------------------- Helpers -------------------------
def _device(device_name: str) -> str:
    return "cuda" if device_name == "auto" and torch.cuda.is_available() else ("cpu" if device_name == "auto" else device_name)

def _safe_joblib_load(path: str):
    return joblib.load(path)

def _align_to_feat_cols(X, feat_cols):
    """Accepts np.ndarray or DataFrame; returns np.float32 array with width == len(feat_cols)."""
    Fexp = len(feat_cols)
    if isinstance(X, pd.DataFrame):
        missing = [c for c in feat_cols if c not in X.columns]
        for c in missing:
            X[c] = 0.0
        X = X[feat_cols]
        return X.to_numpy(dtype=np.float32)
    X = np.asarray(X)
    if X.ndim != 2:
        raise ValueError(f"Features must be 2D [L,F], got shape {X.shape}")
    if X.shape[1] < Fexp:
        pad = np.zeros((X.shape[0], Fexp - X.shape[1]), dtype=X.dtype)
        X = np.concatenate([X, pad], axis=1)
    elif X.shape[1] > Fexp:
        X = X[:, :Fexp]
    return X.astype(np.float32)

def _maybe_apply_calibrator(probs: np.ndarray, calib):
    if calib is None:
        return probs
    try:
        if hasattr(calib, "predict_proba"):
            return calib.predict_proba(probs.reshape(-1, 1))[:, 1]
        if hasattr(calib, "transform"):
            out = calib.transform(probs.reshape(-1, 1))
            return np.asarray(out).ravel()
    except Exception as e:
        warnings.warn(f"Calibrator ignored ({e}).")
    return probs

# ------------------------- Feature loading (classic-first) -------------------------
def load_features_for_id(features_path: str, protein_id: str, feat_cols: list, id_col: str, seq: str, model_name: str):
    """
    Prefer your classic builder:
        X = preProcess_features(features_path, protein_id, model_name)
    If it fails, try on-disk files; if none exist, fall back to 20-AA one-hot padded to feat_cols.
    """
    # 1) Classic pipeline
    try:
        X = preProcess_features(features_path, protein_id, model_name)
        return _align_to_feat_cols(X, feat_cols)
    except Exception as e:
        print(f"preProcess_features failed for {protein_id} ({e}); trying on-disk files...")

    # 2) On-disk per-protein files
    cand_parq = os.path.join(features_path, f"{protein_id}.parquet")
    cand_csv  = os.path.join(features_path, f"{protein_id}.csv")
    cand_npy  = os.path.join(features_path, f"{protein_id}_features.npy")
    combo_parq = os.path.join(features_path, "features.parquet")
    combo_csv  = os.path.join(features_path, "features.csv")

    if os.path.exists(cand_parq):
        df = pd.read_parquet(cand_parq);  return _align_to_feat_cols(df, feat_cols)
    if os.path.exists(cand_csv):
        df = pd.read_csv(cand_csv);       return _align_to_feat_cols(df, feat_cols)
    if os.path.exists(cand_npy):
        arr = np.load(cand_npy);          return _align_to_feat_cols(arr, feat_cols)
    if os.path.exists(combo_parq):
        df = pd.read_parquet(combo_parq); df = df[df[id_col]==protein_id]
        if not df.empty: return _align_to_feat_cols(df, feat_cols)
    if os.path.exists(combo_csv):
        df = pd.read_csv(combo_csv);      df = df[df[id_col]==protein_id]
        if not df.empty: return _align_to_feat_cols(df, feat_cols)

    # 3) One-hot fallback
    aa = "ACDEFGHIKLMNPQRSTVWY"; idx = {a:i for i,a in enumerate(aa)}
    L, Fexp = len(seq), len(feat_cols)
    onehot = np.zeros((L, 20), dtype=np.float32)
    for i, a in enumerate(seq):
        j = idx.get(a)
        if j is not None: onehot[i, j] = 1.0
    if Fexp > 20:
        pad = np.zeros((L, Fexp-20), dtype=np.float32)
        X = np.concatenate([onehot, pad], axis=1)
    else:
        X = onehot[:, :Fexp]
    # print(f"[WARN] Using one-hot fallback for {protein_id}; shape={X.shape}")
    return X

# ------------------------- Load training artifacts & model -------------------------
def load_transformer_model(run_dir: str, device_name: str = "auto"):
    cfg_path = os.path.join(run_dir, "config.json")
    bundle_path = os.path.join(run_dir, "preproc.joblib")
    state_path = os.path.join(run_dir, "best.pt")
    for p in [cfg_path, bundle_path, state_path]:
        if not os.path.exists(p): raise FileNotFoundError(f"Missing: {p}")

    cfg = json.load(open(cfg_path))
    bundle = _safe_joblib_load(bundle_path)
    scaler = bundle["scaler"]
    feat_cols = list(bundle["feat_cols"])
    id_col = bundle["id_col"]
    target_col = bundle["target_col"]

    model = TransformerResidueClassifier(
        input_size=len(feat_cols),
        d_model=int(cfg.get("proj_dim", 512)),
        nhead=int(cfg.get("trans_nhead", 8)),
        num_layers=int(cfg.get("trans_num_layers", 8)),
        dim_ff=int(cfg.get("trans_ff_dim", 2048)),
        dropout=float(cfg.get("dropout", 0.2)),
        input_dropout=float(cfg.get("input_dropout", 0.05)),
        use_stem=bool(cfg.get("use_conv_stem", True)),
    )

    device = _device(device_name)
    state = torch.load(state_path, map_location=device)
    if isinstance(state, dict) and "state_dict" in state:
        state = state["state_dict"]

    missing, unexpected = model.load_state_dict(state, strict=False)
    if missing or unexpected:
        print(f"[WARN] Non-strict load — missing={missing[:5]}{'...' if len(missing)>5 else ''}, "
              f"unexpected={unexpected[:5]}{'...' if len(unexpected)>5 else ''}")
    model.to(device).eval()
    return cfg, model, scaler, feat_cols, id_col, target_col, device

# ------------------------- FASTA inference (writes .caid + timings) -------------------------
def run_fasta_inference(fasta_path: str, features_path: str, output_path: str, run_dir: str, model_name: str, device_name: str = "auto"):
    # ESMDisPred-DNN folder with classic structure
   # ESMDisPred-DNN folder with classic structure
    dnn_root = os.path.join(output_path,"disorder", "ESMDisPred-DNN")
    disorder_dir = dnn_root
    os.makedirs(disorder_dir, exist_ok=True)


    cfg, model, scaler, feat_cols, id_col, target_col, device = load_transformer_model(run_dir, device_name)

    print(f"→ Reading FASTA from: {fasta_path}")
    all_rows = []
    seq_ids, times_ms = [], []

    for rec in SeqIO.parse(fasta_path, "fasta"):
        t0 = time.time()
        pid = rec.id.strip()
        seq = sanitize_sequence(str(rec.seq))
        print(f"  - {pid}: length={len(seq)}")

        # features
        X = load_features_for_id(features_path, pid, feat_cols, id_col, seq, model_name)   # [L, F]
        L = min(len(seq), X.shape[0])
        if X.shape[0] != L:
            X = X[:L, :]
        X_df = pd.DataFrame(X, columns=feat_cols)  # scaler fitted on DF
        Xs = scaler.transform(X_df).astype(np.float32)

        # tensor + predict
        x = torch.from_numpy(Xs).unsqueeze(0).to(device)   # [1,T,F]
        lengths = torch.tensor([L], dtype=torch.long, device=device)
        with torch.no_grad():
            logits = model(x, lengths).squeeze(0).cpu().numpy()[:L]
            probs = 1.0 / (1.0 + np.exp(-logits))

        # save per-protein .caid into output/ESMDisPred-DNN/disorder/<model>/<pid>.caid
        idx = np.arange(1, L + 1).reshape(-1, 1)
        aa_chars = np.array(list(seq[:L])).reshape(-1, 1)
        prob_str = np.char.mod('%.3f', probs[:L]).reshape(-1, 1)
        pred_str = (probs[:L] >= 0.5).astype(int).reshape(-1, 1).astype(str)
        caid_mat = np.hstack([idx, aa_chars, prob_str, pred_str])

        caid_path = os.path.join(disorder_dir, f"{pid}.caid")
        with open(caid_path, "w") as f:
            f.write(f">{pid}\n")
            np.savetxt(f, caid_mat, delimiter="\t", fmt="%s")
        # collect for combined CSV too
        all_rows.append(pd.DataFrame({id_col: [pid]*L, "position": idx.ravel(), "prob": probs[:L]}))

        # timing
        elapsed_ms = int((time.time() - t0) * 1000)
        print(f"    → Time: {elapsed_ms} ms")
        seq_ids.append(pid); times_ms.append(elapsed_ms)

    # combined predictions.csv
    if all_rows:
        combined = pd.concat(all_rows, ignore_index=True)
        combined.to_csv(os.path.join(dnn_root, "predictions.csv"), index=False)

    # timings CSV (classic style)
    label = model_name if model_name else "transformer"
    ts = datetime.datetime.now().astimezone().strftime("%a %b %d %H:%M:%S %Z %Y")

    def _write_timings(path):
        with open(path, "w") as fh:
            print(f"# Running {label}, started {ts}", file=fh)
            print("sequence,milliseconds", file=fh)
            for pid, ms in zip(seq_ids, times_ms):
                print(f"{pid},{ms}", file=fh)

    _write_timings(os.path.join(output_path, f"timings_{label}.csv"))
    _write_timings(os.path.join(output_path, "timings.csv"))

    print(f"→ Per-protein .caid files in: {disorder_dir}")
    print(f"→ Combined predictions: {os.path.join(dnn_root, 'predictions.csv')}")
    print(f"→ Timings: {os.path.join(output_path, 'timings.csv')}")

# ------------------------- CLI -------------------------
if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser(description="ESMDisPred Transformer Inference (classic output format)")
    ap.add_argument("-f", "--fasta_filepath", required=True, help="Path to input FASTA")
    ap.add_argument("-p", "--features_path", required=True, help="Directory holding raw feature inputs for preProcess_features")
    ap.add_argument("-o", "--output_path", required=True, help="Output directory (will create ESMDisPred-DNN/...)")
    ap.add_argument("-r", "--run_dir", required=True, help="Directory with best.pt, preproc.joblib, config.json")
    ap.add_argument("-t", "--model", default="", help="Model name passed to preProcess_features (also used in folder name)")
    ap.add_argument("-d", "--device", default="auto", help="'auto' | 'cpu' | 'cuda'")
    args = ap.parse_args()

    run_fasta_inference(
        args.fasta_filepath,
        args.features_path,
        args.output_path,
        args.run_dir,
        args.model,
        args.device,
    )
