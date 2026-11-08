#!/bin/sh
# T16 (a broken math font must turn the PDF check red) and T17 (unsupported Quarto keys must warn).
# usage: tools/negative_tests.sh [t16|t17|all]     needs quarto, a current TeX Live, python with tools/requirements.txt
# MIT licensed. Exit status 1 when a negative test fails to fail.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
EX="$ROOT/classes/dataimago-thesis/example"
PY=${PYTHON:-python3}
WHICH=${1:-all}
status=0

t17() {
  echo "== T17 unsupported keys"
  R="$ROOT"; out=""
  printf 'toc: false\ntoc-depth: 3\n' > "$EX/_quarto-t17.yml"
  out=$(cd "$EX" && TEXINPUTS="$R/classes/dataimago-thesis//:$R/profiles//:" THESIS_PROFILES_DIR="$R/profiles" QUARTO_PROFILE=house,t17 \
    quarto render --to pdf --output-dir _build/t17 \
      -M geometry:margin=1in -M mainfont:Nonexistent -M monofont:Nonexistent -M linkcolor:red 2>&1 || true)
  rm -f "$EX/_quarto-t17.yml"
  for key in geometry mainfont monofont linkcolor toc toc-depth; do
    echo "$out" | grep -q "dataimago-thesis: '$key' is ignored; set " || { echo "FAIL: no warning for '$key'"; status=1; }
  done
  [ $status -eq 0 ] && echo "ok: every unsupported key produced a warning naming its replacement"
}

t16() {
  echo "== T16 broken math font"
  if ! fc-list 2>/dev/null | grep -qi "Noto Sans Math"; then
    echo "SKIP: Noto Sans Math is not installed (CI installs apt's fonts-noto-core, version 2.001)"; return
  fi
  T=$(mktemp -d)
  mkdir -p "$T/profiles"
  cp "$ROOT/profiles/house.yaml" "$T/profiles/house.yaml"
  cp "$ROOT/tests/negative/noto-math.yaml" "$T/profiles/noto-math.yaml"
  texlua "$ROOT/classes/dataimago-thesis/thesis-profile.lua" "$T/profiles" noto-math
  printf 'thesis:\n  profile: noto-math\n' > "$EX/_quarto-noto-math.yml"
  (cd "$EX" && TEXINPUTS="$ROOT/classes/dataimago-thesis//:$T/profiles//:" THESIS_PROFILES_DIR="$T/profiles" QUARTO_PROFILE=noto-math \
     quarto render --to pdf --output-dir _build/noto-math >/dev/null 2>&1 || true)
  rm -f "$EX/_quarto-noto-math.yml"
  if [ ! -f "$EX/_build/noto-math/thesis.pdf" ]; then
    if grep -qiE "math table|MATH table|not a math font|math font" "$EX/index.log" 2>/dev/null; then
      echo "ok: the build itself stopped on the broken math font (red)"
    else
      echo "FAIL: the build failed, but not on the math font (see index.log); the negative test proved nothing"; status=1
    fi
    rm -rf "$T"; return
  fi
  res=$("$PY" "$ROOT/tools/check_pdf.py" --pdf "$EX/_build/noto-math/thesis.pdf" --profile noto-math --profiles-dir "$T/profiles" 2>&1)
  rc=$?
  echo "$res" | grep -E "T3|math" | head -3
  rm -rf "$T"
  if [ $rc -eq 0 ]; then echo "FAIL: the PDF check stayed green on a silent math-font fallback"; status=1
  elif echo "$res" | grep -q "LatinModernMath"; then echo "ok: check_pdf.py turned red on the fallback"
  else echo "FAIL: red, but not for the math fallback"; status=1; fi
}

case "$WHICH" in t16) t16;; t17) t17;; *) t17; t16;; esac
exit $status
