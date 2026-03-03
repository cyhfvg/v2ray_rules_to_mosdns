#!/usr/bin/env bash
set -euo pipefail

# This script is designed for GitHub Actions workflow.
# It expects:
#   - temp/geosite.dat exists (downloaded by workflow)
#   - temp/mosdns exists and is executable (unzipped by workflow)
# It outputs category txt files to:
#   - data/geosite_<category>.txt

MOSDNS_BIN="temp/mosdns"
GEOSITE_DAT="temp/geosite.dat"
OUT_DIR="data"
STAGE_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${STAGE_DIR}"
}
trap cleanup EXIT

# Hard-coded categories (no args by design).
categories=(
  "category-entertainment"
  "discoveryplus"
  "netflix"
  "disney"
  "hbo"
  "dazn"
  "bahamut"
  "bilibili"
  "viu"
  "category-porn"
)

# Preconditions.
if [[ ! -f "${GEOSITE_DAT}" ]]; then
  echo "ERROR: missing ${GEOSITE_DAT}" >&2
  exit 1
fi

if [[ ! -x "${MOSDNS_BIN}" ]]; then
  echo "ERROR: missing or not executable: ${MOSDNS_BIN}" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

echo "INFO: converting geosite categories -> ${OUT_DIR}"

convert_one() {
  local category="$1"
  echo "INFO: converting: ${category}"

  # mosdns v2dat subcommand:
  # mosdns v2dat unpack-domain -o <dir> "<datfile>:<category>"
  "${MOSDNS_BIN}" v2dat unpack-domain -o "${STAGE_DIR}" "${GEOSITE_DAT}:${category}"

  # v2dat outputs: geosite_<category>.txt in the output dir.
  local out_file="${STAGE_DIR}/geosite_${category}.txt"
  if [[ ! -s "${out_file}" ]]; then
    echo "ERROR: expected output not found or empty: ${out_file}" >&2
    ls -lah "${STAGE_DIR}" >&2 || true
    exit 1
  fi
}

for c in "${categories[@]}"; do
  convert_one "${c}"
done

# Replace only these generated files; keep other data/*.txt (e.g., last_updated.txt) intact.
rm -f "${OUT_DIR}"/geosite_*.txt || true
mv -f "${STAGE_DIR}"/geosite_*.txt "${OUT_DIR}/"

echo "INFO: conversion completed."
