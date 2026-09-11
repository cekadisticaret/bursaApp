#!/usr/bin/env bash
# Native iOS build numarası — project.yml üzerinden.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

read_project() {
  local yml="${1:-$ROOT/project.yml}"
  version_name=$(grep 'MARKETING_VERSION:' "$yml" | head -1 | sed 's/.*MARKETING_VERSION:[[:space:]]*//' | tr -d '"')
  local_build=$(grep 'CURRENT_PROJECT_VERSION:' "$yml" | head -1 | sed 's/.*CURRENT_PROJECT_VERSION:[[:space:]]*//' | tr -d '"')
  [[ "$local_build" =~ ^[0-9]+$ ]] || local_build=0
  [[ -n "$version_name" ]] || version_name="1.0.0"
  PROJECT_YML="$yml"
}

fetch_store_latest() {
  asc=0 tf=0
  if [[ -n "${MOCK_ASC_LATEST:-}" ]]; then
    asc="$MOCK_ASC_LATEST"
  elif [[ -n "${APP_STORE_APPLE_ID:-}" ]] && command -v app-store-connect >/dev/null 2>&1; then
    asc=$(app-store-connect get-latest-app-store-build-number "$APP_STORE_APPLE_ID" 2>/dev/null || echo 0)
    tf=$(app-store-connect get-latest-testflight-build-number "$APP_STORE_APPLE_ID" 2>/dev/null || echo 0)
  fi
  [[ "$asc" =~ ^[0-9]+$ ]] || asc=0
  [[ "$tf" =~ ^[0-9]+$ ]] || tf=0
  latest=$local_build
  for v in "$asc" "$tf"; do
    if [ "$v" -gt "$latest" ]; then latest=$v; fi
  done
  next=$((latest + 1))
}

cmd_resolve() {
  read_project "${1:-$ROOT/project.yml}"
  fetch_store_latest
  echo "version_name=$version_name"
  echo "local_build=$local_build"
  echo "asc_latest=$asc"
  echo "tf_latest=$tf"
  echo "store_latest=$latest"
  echo "next_build=$next"
}

cmd_should_upload() {
  local built="${1:?built}"
  local store_latest="${2:?store_latest}"
  if [ "$built" -le "$store_latest" ]; then
    echo "SKIP: build $built zaten App Store'da (son=$store_latest)"
    return 1
  fi
  echo "UPLOAD: build $built > son $store_latest"
  return 0
}

cmd_apply() {
  local vn="${1:?version_name}"
  local bn="${2:?build_number}"
  local yml="${3:-$ROOT/project.yml}"
  sed -i '' "s/MARKETING_VERSION: .*/MARKETING_VERSION: ${vn}/" "$yml"
  sed -i '' "s/CURRENT_PROJECT_VERSION: .*/CURRENT_PROJECT_VERSION: ${bn}/" "$yml"
}

case "${1:-}" in
  resolve) cmd_resolve "${2:-}" ;;
  should-upload) cmd_should_upload "$2" "$3" ;;
  apply) cmd_apply "$2" "$3" "${4:-}" ;;
  *)
    echo "usage: $0 resolve [project.yml] | should-upload BUILT STORE_LATEST | apply VERSION BUILD [project.yml]"
    exit 2
    ;;
esac
