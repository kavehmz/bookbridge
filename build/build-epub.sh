#!/usr/bin/env bash
# Assemble the bilingual book into an EPUB, entirely inside podman.
# EPUB is HTML-based, so the German .de spans are styled via CSS (build/epub.css),
# NOT the LaTeX filter used for the PDF.
# Generic: derives the book dir from this script's location and includes every
# top-level markdown/*.md (sorted).
set -euo pipefail

BOOKDIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="localhost/bilingual-book:latest"
OUT="${1:-$(basename "$BOOKDIR" | tr ' ' '_')_bilingual.epub}"

cd "$BOOKDIR"
INPUTS=()
for f in $(ls markdown/*.md 2>/dev/null | sort); do INPUTS+=("$f"); done
[ ${#INPUTS[@]} -eq 0 ] && { echo "no markdown/*.md found"; exit 1; }

echo "Assembling ${#INPUTS[@]} markdown files -> pdf/$OUT"

podman run --rm \
  -v "$BOOKDIR":/data \
  -w /data \
  "$IMAGE" \
  pandoc "${INPUTS[@]}" \
    --metadata-file=build/metadata.yaml \
    --css=build/epub.css \
    --toc --toc-depth=1 \
    --split-level=1 \
    -o "pdf/$OUT"

echo "Built: pdf/$OUT"
