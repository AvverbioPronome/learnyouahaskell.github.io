#!/usr/bin/env bash

set -euo pipefail

IN=source_md
OUT=../docs
ASSETS=../docs
TMP=processed_md
STYLE_FIX=$TMP/epub-fix.css

mkdir -p $OUT $TMP

# Adapt the original Website CSS for EPUB
cat <<EOF > $STYLE_FIX
/* Universal Font Stack - No Ligatures */
code, pre, kbd, samp {
    font-family: "Consolas", "Courier New", monospace !important;
    font-variant-ligatures: none !important;
}

/* Block Code: Black Background like the original site */
pre.sourceCode {
    /*background-color: black !important;
    color: white !important;*/
    /* change --highlight-style in the pandoc command if you restore this */
    padding: 10px;
    margin-bottom: 25px;
    border-radius: 4px;
    font-size: 12px;
    line-height: 16px;
    overflow-x: auto;
}

/* Inline Code: Grey 'Pill' look from style.css */
:not(pre) > code {
    background-color: #ddd !important;
    color: black !important;
    font-weight: bold;
    padding: 0px 3px;
    border-radius: 4px;
    text-wrap: wrap;
}

/* Image scaling: Prevent the 'giant icon' problem */
/* Based on your original 'img' rules but adding height constraints for icons */
img {
    max-width: 100%;
    height: auto;
}

/* If it's a small icon in a paragraph (like the lemon or note) */
p img:not(.center, .left, .right) {
    max-height: 1.2em;
    width: auto;
    vertical-align: middle;
}

/* Original float classes */
img.right { float: right; margin: 10px; max-width: 40%; }
img.left { float: left; margin: 10px; max-width: 40%; }
img.center { margin: 10px auto 25px auto; display: block; max-width: 100%; }

/* Note/Hint box styling */
.hintbox {
    padding: 10px;
    background-color: #ffc;
    margin-bottom: 25px;
    border-left: 5px solid #ffd700;
}
EOF

# Read the file list into an array
mapfile -t filenames < config/file-list.txt

# Add the directory prefix AND the .md extension to every item
# Syntax: ${variable/%/suffix} appends to the end
input_files=("${filenames[@]/#/$IN/}")
input_files=("${input_files[@]/%/.md}")

# Pre-process the Markdown
for file in "${filenames[@]}"; do
    # A. Simplify the code fences to standard .haskell
    # B. Wrap "ghci>" in a span for CSS styling
    sed 's/^```{\.haskell.*}/```haskell/' "$IN/$file.md" > "$TMP/$file.md"
done

# Prepare the file list for Pandoc
input_files=("${filenames[@]/#/$TMP/}")
input_files=("${input_files[@]/%/.md}")

# Run Pandoc once for the entire book
# Note: We omit the manual TOC and nav links as ePub handles this natively
# 5. Run Pandoc
pandoc "${input_files[@]}" \
    --from=markdown-implicit_figures \
    --toc \
    --toc-depth=2 \
    --resource-path=".:$IN:$ASSETS" \
    --highlight-style=tango \
    --css=$STYLE_FIX \
    --metadata title="Learn You a Haskell for Great Good!" \
    --metadata author="Miran Lipovača" \
    -o "$OUT/lyah.epub"

echo "ePub generated at $OUT/lyah.epub"

# Clean up
rm -rf $TMP
# rm $STYLE_FIX  # Uncomment if you don't want to keep the CSS file