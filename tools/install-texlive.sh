#!/bin/sh
# Installs the pinned TeX Live snapshot (tools/texlive-pin.txt; scheme-medium plus
# tools/texlive-packages.txt) into $HOME/texlive. CI caches that directory, keyed on the pin.
# The tagged-PDF code moves with the LaTeX kernel, so the snapshot is bumped on purpose, with this
# repository's CI as the gate (docs/house-class-spec.md section 5.2). Fonts come from TeX Live
# (TeX Gyre); none are committed.
set -eu
TL=${TL:-$HOME/texlive}
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck disable=SC1091
. "$HERE/texlive-pin.txt"
REPO="https://texlive.info/tlnet-archive/$TL_SNAPSHOT/tlnet"
sha512() { if command -v sha512sum >/dev/null 2>&1; then sha512sum "$1"; else shasum -a 512 "$1"; fi | cut -d' ' -f1; }
WORK=$(mktemp -d)
cd "$WORK"
# Download to a file first: a retried download piped into tar could leave tar a truncated stream.
curl -fsSL --retry 4 --retry-delay 5 --retry-all-errors -o install-tl-unx.tar.gz "$REPO/install-tl-unx.tar.gz"
[ "$(sha512 install-tl-unx.tar.gz)" = "$TL_INSTALLER_SHA512" ] || { echo "install-tl-unx.tar.gz from $REPO does not match TL_INSTALLER_SHA512" >&2; exit 1; }
curl -fsSL --retry 4 --retry-delay 5 --retry-all-errors -o texlive.tlpdb.sha512 "$REPO/tlpkg/texlive.tlpdb.sha512"
[ "$(cut -d' ' -f1 texlive.tlpdb.sha512)" = "$TL_TLPDB_SHA512" ] || { echo "the package database at $REPO is not the pinned one (TL_TLPDB_SHA512)" >&2; exit 1; }
tar xzf install-tl-unx.tar.gz --strip-components=1
cat > profile.txt <<EOP
selected_scheme scheme-medium
TEXDIR $TL
TEXMFLOCAL $TL/texmf-local
TEXMFSYSCONFIG $TL/texmf-config
TEXMFSYSVAR $TL/texmf-var
TEXMFHOME $TL/texmf-home
instopt_adjustpath 0
instopt_adjustrepo 0
tlpdbopt_autobackup 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
EOP
perl ./install-tl --profile profile.txt --no-interaction --repository "$REPO"
BIN=$(ls -d "$TL"/bin/*)
# tlmgr installs from the same snapshot, never from the current CTAN mirror
"$BIN/tlmgr" option repository "$REPO"
# shellcheck disable=SC2046
"$BIN/tlmgr" install $(grep -v '^#' "$HERE/texlive-packages.txt" | tr '\n' ' ')
"$BIN/tlmgr" --version
