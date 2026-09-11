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

cmd_apply_pbxproj() {
  local vn="${1:?version_name}"
  local bn="${2:?build_number}"
  local pbx="${3:-$ROOT/BursaApp.xcodeproj/project.pbxproj}"
  [[ -f "$pbx" ]] || return 0
  sed -i '' "s/CURRENT_PROJECT_VERSION = [^;]*;/CURRENT_PROJECT_VERSION = ${bn};/g" "$pbx"
  sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = ${vn};/g" "$pbx"
}

cmd_ipa_build_number() {
  local ipa="${1:?ipa}"
  local plist_path plist
  plist_path=$(unzip -Z1 "$ipa" 2>/dev/null | grep -E '^Payload/[^/]+\.app/Info\.plist$' | head -1 || true)
  [[ -n "$plist_path" ]] || { echo ""; return 1; }
  plist=$(unzip -p "$ipa" "$plist_path" 2>/dev/null || true)
  [[ -n "$plist" ]] || { echo ""; return 1; }
  if command -v plutil >/dev/null 2>&1; then
    printf '%s' "$plist" | plutil -extract CFBundleVersion raw - 2>/dev/null || true
  else
    printf '%s' "$plist" | grep -A1 CFBundleVersion | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/'
  fi
}

case "${1:-}" in
  resolve) cmd_resolve "${2:-}" ;;
  should-upload) cmd_should_upload "$2" "$3" ;;
  apply) cmd_apply "$2" "$3" "${4:-}" ;;
  apply-pbxproj) cmd_apply_pbxproj "$2" "$3" "${4:-}" ;;
  ipa-build) cmd_ipa_build_number "$2" ;;
  *)
    echo "usage: $0 resolve [project.yml] | should-upload BUILT STORE_LATEST | apply VERSION BUILD [project.yml] | apply-pbxproj VERSION BUILD [pbxproj] | ipa-build IPA"
    exit 2
    ;;
esac
