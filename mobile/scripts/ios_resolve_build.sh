#!/usr/bin/env bash
# App Store Connect build numarası — Codemagic + yerel test.
# Kullanım:
#   ./scripts/ios_resolve_build.sh resolve [pubspec.yaml]
#   ./scripts/ios_resolve_build.sh should-upload 7 7   # built, latest → exit 0 skip
#   MOCK_ASC_LATEST=6 ./scripts/ios_resolve_build.sh resolve

set -euo pipefail

resolve_build() {
  local pubspec="${1:-pubspec.yaml}"
  local version_line
  version_line=$(grep '^version:' "$pubspec")
  local version_name local_build
  version_name=$(echo "$version_line" | sed 's/version:[[:space:]]*//' | cut -d'+' -f1)
  local_build=$(echo "$version_line" | sed 's/version:[[:space:]]*//' | cut -d'+' -f2)
  [[ "$local_build" =~ ^[0-9]+$ ]] || local_build=0

  local asc=0 tf=0
  if [[ -n "${MOCK_ASC_LATEST:-}" ]]; then
    asc="$MOCK_ASC_LATEST"
  elif [[ -n "${APP_STORE_APPLE_ID:-}" ]] && command -v app-store-connect >/dev/null 2>&1; then
    asc=$(app-store-connect get-latest-app-store-build-number "$APP_STORE_APPLE_ID" 2>/dev/null || echo 0)
    tf=$(app-store-connect get-latest-testflight-build-number "$APP_STORE_APPLE_ID" 2>/dev/null || echo 0)
  fi
  [[ "$asc" =~ ^[0-9]+$ ]] || asc=0
  [[ "$tf" =~ ^[0-9]+$ ]] || tf=0

  local latest=$local_build
  for v in "$asc" "$tf"; do
    if [ "$v" -gt "$latest" ]; then latest=$v; fi
  done
  local next=$((latest + 1))

  echo "version_name=$version_name"
  echo "local_build=$local_build"
  echo "asc_latest=$asc"
  echo "tf_latest=$tf"
  echo "store_latest=$latest"
  echo "next_build=$next"
}

should_upload() {
  local built="${1:?built}"
  local store_latest="${2:?store_latest}"
  if [ "$built" -le "$store_latest" ]; then
    echo "SKIP: build $built zaten App Store'da (son=$store_latest)"
    return 1
  fi
  echo "UPLOAD: build $built > son $store_latest"
  return 0
}

case "${1:-}" in
  resolve) resolve_build "${2:-pubspec.yaml}" ;;
  should-upload) should_upload "$2" "$3" ;;
  *)
    echo "usage: $0 resolve [pubspec] | should-upload BUILT STORE_LATEST"
    exit 2
    ;;
esac
