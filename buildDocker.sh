#! /bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

docker build -t wasicse/esmdispred:latest .

# docker push wasicse/esmdispred:latest
