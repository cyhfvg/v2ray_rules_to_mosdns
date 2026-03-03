#!/usr/bin/env bash
set -euo pipefail

# This script is designed for GitHub Actions workflow.
# It expects:
#   - temp/geosite.dat exists (downloaded by workflow)
#   - temp/geoip.dat exists (downloaded by workflow)
#   - temp/mosdns exists and is executable (unzipped by workflow)
# It outputs txt files to:
#   - data/geoip_cn.txt
#   - data/geosite_<category>.txt

MOSDNS_BIN="temp/mosdns"
GEOSITE_DAT="temp/geosite.dat"
GEOIP_DAT="temp/geoip.dat"
OUT_DIR="data"
STAGE_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${STAGE_DIR}"
}
trap cleanup EXIT

# Hard-coded geosite entries (no args by design).
# These are v2ray geosite entry names (NOT filenames).
geosite_entries=(
  "cn"
  "apple-cn"
  "icloud"
  "google-cn"
  "tld-cn"
  "geolocation-!cn"
)

# Preconditions.
if [[ ! -x "${MOSDNS_BIN}" ]]; then
  echo "ERROR: missing or not executable: ${MOSDNS_BIN}" >&2
  exit 1
fi

if [[ ! -f "${GEOSITE_DAT}" ]]; then
  echo "ERROR: missing ${GEOSITE_DAT}" >&2
  exit 1
fi

if [[ ! -f "${GEOIP_DAT}" ]]; then
  echo "ERROR: missing ${GEOIP_DAT}" >&2
  exit 1
fi

mkdir -p "${OUT_DIR}"

echo "INFO: generating geoip_cn.txt"
# Unpack CN IP set from geoip.dat
"${MOSDNS_BIN}" v2dat unpack-ip -o "${STAGE_DIR}" "${GEOIP_DAT}:cn"

if [[ ! -s "${STAGE_DIR}/geoip_cn.txt" ]]; then
  echo "ERROR: expected output not found or empty: ${STAGE_DIR}/geoip_cn.txt" >&2
  ls -lah "${STAGE_DIR}" >&2 || true
  exit 1
fi

echo "INFO: generating geosite entries -> ${OUT_DIR}"
for entry in "${geosite_entries[@]}"; do
  echo "INFO: converting geosite entry: ${entry}"
  "${MOSDNS_BIN}" v2dat unpack-domain -o "${STAGE_DIR}" "${GEOSITE_DAT}:${entry}"

  out_file="${STAGE_DIR}/geosite_${entry}.txt"
  if [[ ! -s "${out_file}" ]]; then
    echo "ERROR: expected output not found or empty: ${out_file}" >&2
    ls -lah "${STAGE_DIR}" >&2 || true
    exit 1
  fi
done

# Replace only our generated files; keep other data/* intact (e.g., last_updated.txt).
rm -f "${OUT_DIR}/geoip_cn.txt" || true
rm -f "${OUT_DIR}/geosite_"*.txt || true

mv -f "${STAGE_DIR}/geoip_cn.txt" "${OUT_DIR}/geoip_cn.txt"
mv -f "${STAGE_DIR}/geosite_"*.txt "${OUT_DIR}/"

echo "INFO: conversion completed."
