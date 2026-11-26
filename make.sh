#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Build LiandriExchange for Unreal Tournament 2004.
#
# Uses UCC with -package and -path flags (works on Linux native UCC.bin)
# and deploys the compiled package + metadata to System/.
#
# Requirements:
#   game root: $UT2004_DIR (default $HOME/Juegos/UT2004)
#   Linux native UCC.bin in System/
#
# Usage: ./make.sh
# ---------------------------------------------------------------------------
set -euo pipefail

GAME_DIR="${UT2004_DIR:-$HOME/Juegos/UT2004}"
SYS="$GAME_DIR/System"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$SCRIPT_DIR"
PKG="LiandriExchange"
SRC_CLASSES="$ROOT/Classes"

if [ ! -f "$SYS/UCC.bin" ]; then
    echo "ERROR: UCC.bin not found in $SYS - set UT2004_DIR" >&2
    exit 1
fi

# --- compile (fresh) --------------------------------------------------------
cd "$SYS"
rm -f "$PKG.u"
echo "== ucc make =="
WINEDEBUG=-all DISPLAY= ./UCC.bin make \
    -nohomedir \
    -package="$PKG" \
    -path="$SRC_CLASSES;." \
    2>&1 | grep -v -E '^fixme:|^err:' | tail -40 || true

if [ ! -f "$PKG.u" ]; then
    echo
    echo "== BUILD FAILED - last 40 lines of UCC.log: =="
    tail -40 UCC.log
    exit 1
fi

# --- deploy metadata next to the compiled package --------------------------
cp -f "$ROOT/Resources/LiandriExchange.int" "$SYS/LiandriExchange.int"
if [ -f "$ROOT/LiandriExchange.ucl" ]; then
    cp -f "$ROOT/LiandriExchange.ucl" "$SYS/LiandriExchange.ucl"
fi
echo
echo "== $PKG.u built; $PKG.int/$PKG.ucl deployed to $SYS =="

# --- refresh tracked release artifacts --------------------------------------
mkdir -p "$ROOT/prebuilt/System"
cp -f "$SYS/$PKG.u" "$ROOT/prebuilt/System/$PKG.u"
cp -f "$ROOT/Resources/LiandriExchange.int" "$ROOT/prebuilt/System/LiandriExchange.int"
if [ -f "$ROOT/LiandriExchange.ucl" ]; then
    cp -f "$ROOT/LiandriExchange.ucl" "$ROOT/prebuilt/System/LiandriExchange.ucl"
fi
SRC_HASH="$(find "$SRC_CLASSES" -name '*.uc' -type f -exec sha256sum {} + | sha256sum | cut -d' ' -f1)"
GIT_COMMIT="$(git -C "$ROOT" rev-parse --verify HEAD 2>/dev/null || echo unknown)"
{
    echo "source-sha256=$SRC_HASH"
    echo "commit=$GIT_COMMIT"
    echo "built=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$ROOT/prebuilt/BUILD"
echo "== release artifacts refreshed in $ROOT/prebuilt =="
echo "== done. Enable 'Liandri Exchange' in the Mutators menu. =="