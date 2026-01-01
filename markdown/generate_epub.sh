#!/usr/bin/env bash

set -euo pipefail

IN=source_md
OUT=../docs
ASSETS=../docs
TMP=.tmp
STYLE_FIX=book.css
LUA_FILTER=CodeBlock.lua

mkdir -p $OUT $TMP

# Read the file list into an array
mapfile -t filenames < config/file-list.txt

# Add the directory prefix AND the .md extension to every item
# Syntax: ${variable/%/suffix} appends to the end
input_files=("${filenames[@]/#/$IN/}")
input_files=("${input_files[@]/%/.md}")

# Run Pandoc
pandoc "${input_files[@]}" \
    --from=markdown-implicit_figures \
    --toc \
    --toc-depth=2 \
    --resource-path=".:$IN:$ASSETS" \
    --syntax-highlighting=tango \
    --css=$STYLE_FIX \
    --css=tango.css \
    --lua-filter=$LUA_FILTER \
    --metadata title="Learn You a Haskell for Great Good!" \
    --metadata author="Miran Lipovača" \
    -o "$OUT/lyah.epub"

echo "ePub generated at $OUT/lyah.epub"