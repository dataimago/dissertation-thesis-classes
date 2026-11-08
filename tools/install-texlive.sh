#!/bin/sh
# Installs a current TeX Live (scheme-medium plus tools/texlive-packages.txt) into $HOME/texlive.
# CI caches that directory. The tagged-PDF code is in rapid development, so TeX Live must be
# current (docs/house-class-spec.md section 5.2). Fonts come from TeX Live (TeX Gyre); none are committed.
set -eu
TL=${TL:-$HOME/texlive}
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p /tmp/tlinst
cd /tmp/tlinst
curl -fsSL https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | tar xz --strip-components=1
cat > profile.txt <<EOP
selected_scheme scheme-medium
TEXDIR $TL
TEXMFLOCAL $TL/texmf-local
TEXMFSYSCONFIG $TL/texmf-config
TEXMFSYSVAR $TL/texmf-var
TEXMFHOME $TL/texmf-home
instopt_adjustpath 0
instopt_adjustrepo 1
tlpdbopt_autobackup 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
EOP
perl ./install-tl --profile profile.txt --no-interaction
BIN=$(ls -d "$TL"/bin/*)
# shellcheck disable=SC2046
"$BIN/tlmgr" install $(grep -v '^#' "$HERE/texlive-packages.txt" | tr '\n' ' ')
"$BIN/tlmgr" --version
