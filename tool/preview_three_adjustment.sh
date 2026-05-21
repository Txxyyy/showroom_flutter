#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${1:-5186}"

find_available_port() {
  local candidate="$1"
  while lsof -tiTCP:"${candidate}" -sTCP:LISTEN >/dev/null 2>&1; do
    candidate="$((candidate + 1))"
  done
  echo "${candidate}"
}

PORT="$(find_available_port "${PORT}")"
PREVIEW_URL="http://127.0.0.1:${PORT}/assets/three_adjustment/index.html?embedded=0&ui=1&transparent=0&mode=flat&autorun=0&performance=balanced&renderMode=onDemand"

echo "Smart Mattress 3D preview"
echo "Root: ${ROOT_DIR}"
echo "URL:  ${PREVIEW_URL}"
echo
echo "Press Ctrl+C to stop."

cd "${ROOT_DIR}"
python3 -m http.server "${PORT}" --bind 127.0.0.1
