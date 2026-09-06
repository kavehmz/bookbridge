#!/usr/bin/env bash
# Assemble the bilingual book into one PDF, entirely inside podman.
# Generic: derives the book dir from this script's location and includes every
# top-level markdown/*.md (sorted). Name files so sort order = reading order
# (e.g. 00-howto.md, 10-story.md, or ch01.md..ch32.md).
set -euo pipefail

BOOKDIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="localhost/bilingual-book:latest"
OUT="${1:-$(basename "$BOOKDIR" | tr ' ' '_')_bilingual.pdf}"

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
    --pdf-engine=pdflatex \
    --lua-filter=build/de-span.lua \
    --lua-filter=build/pagebreak.lua \
    --lua-filter=build/grammar-div.lua \
    -H build/header.tex \
    --toc --toc-depth=1 \
    -V geometry:"margin=2.4cm" \
    -V fontsize=12pt \
    -V linkcolor=germ \
    -V toccolor=black \
    -o "pdf/$OUT"

echo "Built: pdf/$OUT"
