#!/bin/bash
# Build script for LiandriExchange mutator
# Compiles with UCC (via Wine) against UT2004 v3374

UT2004_PATH="/home/jdmr/Juegos/UT2004"
UCC="${UT2004_PATH}/System/UCC.exe"
SRC_PATH="/home/jdmr/Proyectos/ut2k4mutators/LiandriExchange/Classes"
RES_PATH="/home/jdmr/Proyectos/ut2k4mutators/LiandriExchange/Resources"
PKG_PATH="${UT2004_PATH}/System"

echo "=== LiandriExchange Build Script ==="
echo "UT2004 Path: ${UT2004_PATH}"
echo "Source Path: ${SRC_PATH}"
echo ""

# Check UCC exists
if [ ! -f "${UCC}" ]; then
    echo "ERROR: UCC.exe not found at ${UCC}"
    exit 1
fi

# Check Wine
if ! command -v wine &> /dev/null; then
    echo "ERROR: Wine not found. Install wine to run UCC.exe"
    exit 1
fi

# Clean previous build
echo "Cleaning previous build..."
rm -f "${PKG_PATH}/LiandriExchange.u"
rm -f "${PKG_PATH}/LiandriExchange.int"

# Compile
echo "Compiling with UCC (via Wine)..."
cd "${UT2004_PATH}/System"
wine "${UCC}" make \
    -path="$(winepath -w "${SRC_PATH}");$(winepath -w "${PKG_PATH}")" \
    -package=LiandriExchange \
    -lang=int \
    -output="$(winepath -w "${PKG_PATH}/LiandriExchange.u")" \
    2>&1 | tee /tmp/liandri_build.log

BUILD_RESULT=${PIPESTATUS[0]}

if [ ${BUILD_RESULT} -eq 0 ]; then
    echo ""
    echo "=== BUILD SUCCESSFUL ==="
    echo "Package created: ${PKG_PATH}/LiandriExchange.u"
    
    # Copy .int file
    cp "${RES_PATH}/LiandriExchange.int" "${PKG_PATH}/LiandriExchange.int"
    echo "Localization copied: ${PKG_PATH}/LiandriExchange.int"
    
    # Verify package
    echo ""
    echo "Verifying package..."
    wine "${UCC}" package info "$(winepath -w "${PKG_PATH}/LiandriExchange.u")"
else
    echo ""
    echo "=== BUILD FAILED ==="
    cat /tmp/liandri_build.log
    exit 1
fi

echo ""
echo "To test: Add 'ServerPackages=LiandriExchange' to UT2004.ini [Engine.GameEngine] section"
echo "Then run: wine ${UT2004_PATH}/System/UT2004.exe DM-Deck17?game=XGame.xDeathMatch?mutator=LiandriExchange.LiandriExchangeMutator"