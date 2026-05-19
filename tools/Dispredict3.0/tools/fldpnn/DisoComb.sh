#!/bin/bash
# Modified DisoComb.sh — full parallelization + Singularity-safe temp file handling.
#
# Problem (Singularity without --writable-tmpfs):
#   DisoRDPbind, fMoRFpred, and DFLpred use relative paths internally (./bin,
#   ./psipred, ./myIUPRED, etc.) AND write temp files to CWD.  The SIF container
#   filesystem is read-only, so writes to the tool program dirs fail.
#
# Solution — two-level symlink workdir (works in local, Docker, AND Singularity):
#
#   make_tool_workdir <prog_dir>  creates a mktemp dir where:
#     • Each FILE   in prog_dir → symlink  (points into SIF, read-only is fine)
#     • Each SUBDIR in prog_dir → REAL dir with symlinks to its entries (one level)
#
#   Why real subdirs?  Linux resolves `cd symlink/` to the symlink target, so
#   `../` from inside a symlinked subdir would go into the SIF parent — still
#   read-only.  A real dir in /tmp keeps `../` inside the writable mktemp tree.
#
#   All temp writes (psitmp*.mtx, .ss, .horiz, temp<timestamp>/, etc.) land in
#   the mktemp tree under /tmp — writable everywhere without --writable-tmpfs.
#
# Parallelism:
#   - DisoRDPbind, fMoRFpred, DFLpred run concurrently (independent)
#   - PSI-BLAST runs in parallel (xargs -P nproc) with persistent PSSM cache
#   - All per-sequence steps run in a single parallel xargs loop

set -uo pipefail

DIRNAME=$1

SCRIPT=$(readlink -f "$0")
SHPATH=$(dirname "$SCRIPT")

if [ $# -eq 0 ]; then
    echo "Usage: ./DisoComb.sh fastafile"
    exit
fi

if [ ! -e "$DIRNAME" ]; then
    echo "File doesn't exist: $DIRNAME"
    exit 1
fi

if [ "${DIRNAME:0:1}" = "/" ]; then
    ABSDIR=$(dirname "$DIRNAME")
else
    ABSDIR="$(pwd)/$(dirname "$DIRNAME")"
fi

FILENAME=${DIRNAME##*/}
FNAME=${FILENAME%.*}
TMPDIR=$ABSDIR/"tmp_"$FNAME
SCOREDIR=$ABSDIR/"features_"$FNAME
PREDIR=$ABSDIR/"pred_"$FNAME

mkdir -p "$TMPDIR" "$SCOREDIR" "$PREDIR"

# Create a mktemp working dir mirroring a tool's program directory:
#   - Top-level files   → symlinks into the (possibly read-only) SIF
#   - Top-level subdirs → real dirs in /tmp, with one-level-deep symlinks inside
# This lets the tool read its resources via relative paths AND write temp files
# without touching the read-only SIF, even when it `cd`s into a subdir and uses
# `../` to navigate back.
make_tool_workdir() {
    local prog_dir="$1"
    local work_dir
    work_dir=$(mktemp -d)
    local f bname sf
    for f in "$prog_dir"/*; do
        [ -e "$f" ] || continue
        bname=$(basename "$f")
        if [ -d "$f" ]; then
            mkdir -p "$work_dir/$bname"
            for sf in "$f"/*; do
                [ -e "$sf" ] && ln -s "$sf" "$work_dir/$bname/$(basename "$sf")"
            done
        else
            ln -s "$f" "$work_dir/$bname"
        fi
    done
    echo "$work_dir"
}

# ── Step 1: Run 3 whole-fasta predictors concurrently ─────────────────────────
rdp_work=$(make_tool_workdir "$SHPATH/programs/DisoRDPbind")
(cd "$rdp_work" && \
    ./DisoRDPbind "$ABSDIR/$FILENAME" "$TMPDIR/${FNAME}_disordpbind.predictions"
 rm -rf "$rdp_work") &
PID_RDP=$!

fmorf_work=$(make_tool_workdir "$SHPATH/programs/fMoRFpred")
(cd "$fmorf_work" && \
    ./fMoRFpred.sh "$ABSDIR/$FILENAME" "$TMPDIR/${FNAME}_fmorfpred.predictions"
 rm -rf "$fmorf_work") &
PID_FMORF=$!

dfl_work=$(make_tool_workdir "$SHPATH/programs/DFLpred")
(cd "$dfl_work" && \
    java -jar ./DFLpred.jar "$ABSDIR/$FILENAME" "$TMPDIR/${FNAME}_dflpred.predictions"
 rm -rf "$dfl_work") &
PID_DFL=$!

wait $PID_RDP $PID_FMORF $PID_DFL || true

# Build ID list from .seq files created by the predictors
ls "$TMPDIR"/*.seq | while read line; do
    a=${line##*/}
    echo "${a%%.seq}"
done > "$TMPDIR/idlist"

# ── Step 2: Parallel PSI-BLAST with PSSM cache ────────────────────────────────
# psiblast writes psitmp*.mtx to its CWD — run from a plain mktemp dir.
# All paths are absolute so no symlink workdir needed.
NPROC=$(nproc)
CACHE_DIR="${PSSM_CACHE:-}"

run_one_blast() {
    local id="$1"
    local TMPDIR="$2"
    local PREDIR="$3"
    local SHPATH="$4"
    local CACHE_DIR="$5"

    local cache_key cached_pssm=""
    cache_key=$(md5sum "$TMPDIR/$id.seq" | awk '{print $1}')
    [[ -n "$CACHE_DIR" ]] && cached_pssm="$CACHE_DIR/${cache_key}.pssm"

    if [[ -n "$cached_pssm" && -f "$cached_pssm" ]]; then
        cp "$cached_pssm" "$TMPDIR/$id.pssm"
        return 0
    fi

    local blast_work
    blast_work=$(mktemp -d)
    (cd "$blast_work" && \
        "$SHPATH/programs/blast-2.2.24/bin/psiblast" \
            -query "$TMPDIR/$id.seq" \
            -db "$SHPATH/programs/blast-2.2.24/db/swissprot" \
            -num_iterations 3 \
            -out "$TMPDIR/$id.out" \
            -out_ascii_pssm "$TMPDIR/$id.pssm" \
            2>/dev/null) || true
    rm -rf "$blast_work"

    if [[ ! -f "$TMPDIR/$id.pssm" ]]; then
        touch "$PREDIR/use_default_pssm_$id"
        "$SHPATH/programs/create_default_pssm" "$TMPDIR/$id.seq" > "$TMPDIR/$id.pssm"
    elif [[ -n "$cached_pssm" ]]; then
        cp "$TMPDIR/$id.pssm" "${cached_pssm}.tmp.$$"
        mv "${cached_pssm}.tmp.$$" "$cached_pssm"
    fi
}

export -f run_one_blast
export PSSM_CACHE="${PSSM_CACHE:-}" TMPDIR PREDIR SHPATH

xargs -P "$NPROC" -I{} bash -c \
    'run_one_blast "$@"' _ {} "$TMPDIR" "$PREDIR" "$SHPATH" "$CACHE_DIR" \
    < "$TMPDIR/idlist"

# ── Step 3: All per-sequence steps in one parallel loop ───────────────────────
OUTDIR="$SHPATH/output"
mkdir -p "$OUTDIR"
export IUPred_PATH="$SHPATH/programs/iupred"

run_one_sequence() {
    local id="$1"
    local TMPDIR="$2"
    local SCOREDIR="$3"
    local PREDIR="$4"
    local SHPATH="$5"
    local FNAME="$6"
    local OUTDIR="$7"

    # PSSM post-processing
    local pssm="$TMPDIR/$id.pssm"
    if [[ -f "$pssm" ]]; then
        sed '1,3d' "$pssm" | tac | sed '1,6d' | tac > "${pssm}.clean"
        mv "${pssm}.clean" "$pssm"
    fi

    # IUPred — writes only to stdout; absolute path + env var
    export IUPred_PATH="$SHPATH/programs/iupred"
    "$SHPATH/programs/iupred/iupred" "$TMPDIR/$id.seq" long  | grep -v '^#' > "$TMPDIR/$id.long"
    "$SHPATH/programs/iupred/iupred" "$TMPDIR/$id.seq" short | grep -v '^#' > "$TMPDIR/$id.short"

    # Feature generation
    grep ">$id" -A 2 "$TMPDIR/${FNAME}_dflpred.predictions"    | sed 's/,/ /g' > "$TMPDIR/$id.dfl"
    grep ">$id" -A 7 "$TMPDIR/${FNAME}_disordpbind.predictions" | sed 's/,/ /g' | sed "s/.*binding.*://g" > "$TMPDIR/$id.rdp"
    grep ">$id" -A 4 "$TMPDIR/${FNAME}_fmorfpred.predictions"   | sed 's/,/ /g' > "$TMPDIR/$id.fmorf"

    # logitReg — binary only (no data files); takes TMPDIR as explicit arg
    local lr_work
    lr_work=$(mktemp -d)
    (cd "$lr_work" && "$SHPATH/programs/logReg/logitReg" "$TMPDIR" "$id") || true
    rm -rf "$lr_work"

    [[ -f "$TMPDIR/$id.score" ]] || return 0
    mv "$TMPDIR/$id.score"    "$SCOREDIR/$id.score"
    [[ -f "$TMPDIR/$id.log.pred" ]] && mv "$TMPDIR/$id.log.pred" "$PREDIR/$id.log.pred" || true

    # NNpackage — per-sequence mktemp avoids conflicts between parallel workers
    local nn_tmp
    nn_tmp=$(mktemp -d)
    cut -d $'\t' -f 3-317 "$SCOREDIR/$id.score" > "$nn_tmp/$id.ttscore"
    cut -d $'\t' -f 1-2   "$SCOREDIR/$id.score" > "$nn_tmp/$id.ttindex"
    (cd "$SHPATH/programs/NNpackage/" && python3 Disnet.py "$nn_tmp/$id.ttscore") > "$nn_tmp/$id.ttpreds"
    paste "$nn_tmp/$id.ttindex" "$nn_tmp/$id.ttpreds" > "$PREDIR/$id.nn.pred"
    cp "$nn_tmp"/* "$OUTDIR/"
    rm -rf "$nn_tmp"
}

export -f run_one_sequence
export SHPATH TMPDIR SCOREDIR PREDIR FNAME OUTDIR

xargs -P "$NPROC" -I{} bash -c \
    'run_one_sequence "$@"' _ {} "$TMPDIR" "$SCOREDIR" "$PREDIR" "$SHPATH" "$FNAME" "$OUTDIR" \
    < "$TMPDIR/idlist"

# ── Cleanup ───────────────────────────────────────────────────────────────────
[[ -d "$TMPDIR"   ]] && rm -rf "$TMPDIR"
[[ -d "$SCOREDIR" ]] && rm -rf "$SCOREDIR"
