#!/bin/sh
# usage: ./render.sh <profile> <engine> [output-dir]   (needs quarto, a current TeX Live, the TeX Gyre fonts)
# Regenerates the profile .cfg from profiles/<id>.yaml, then renders the book to PDF.
set -eu
PROFILE=${1:-house}; ENGINE=${2:-lualatex}; OUT=${3:-_build/$PROFILE-$ENGINE}
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
texlua "$ROOT/classes/dataimago-thesis/thesis-profile.lua" "$ROOT/profiles" "$PROFILE"
export TEXINPUTS="$ROOT/classes/dataimago-thesis//:$ROOT/profiles//:"
export THESIS_PROFILES_DIR="$ROOT/profiles"
cd "$HERE"
if [ "$ENGINE" = xelatex ] && ! fc-list 2>/dev/null | grep -qi "TeX Gyre Termes"; then
  # XeLaTeX finds fonts through fontconfig; point it at TeX Live's OpenType fonts as well.
  FC="$HERE/_build/fontconfig"; mkdir -p "$FC"
  SYS=$(for f in /etc/fonts/fonts.conf /opt/homebrew/etc/fonts/fonts.conf /usr/local/etc/fonts/fonts.conf; do [ -f "$f" ] && echo "$f" && break; done)
  printf '<?xml version="1.0"?>\n<!DOCTYPE fontconfig SYSTEM "fonts.dtd">\n<fontconfig>\n<include ignore_missing="yes">%s</include>\n<dir>%s/fonts/opentype</dir>\n<cachedir>%s/cache</cachedir>\n</fontconfig>\n' "$SYS" "$(kpsewhich -var-value TEXMFDIST)" "$FC" > "$FC/fonts.conf"
  export FONTCONFIG_FILE="$FC/fonts.conf"
fi
QUARTO_PROFILE="$PROFILE" quarto render --to pdf -M "pdf-engine:$ENGINE" --output-dir "$OUT" ${QUARTO_EXTRA:-}
