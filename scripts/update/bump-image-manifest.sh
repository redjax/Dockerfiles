#!/usr/bin/env bash
set -euo pipefail

################################################
# Bump image tags                              #
#                                              #
# This script reads a given image.yml file,    #
# checks for new versions of upstream images,  #
# and bumps the version if there is a newer    #
# release.                                     #
################################################

## Ensure required packages are installed
for cmd in curl yq jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[ERROR] $cmd is not installed" >&2
    exit 1
  fi
done

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${THIS_DIR}/lib"

## Source container registry libs
source "${LIB_DIR}/dockerhub.sh"
source "${LIB_DIR}/ghcr.sh"
source "${LIB_DIR}/gitlab.sh"
source "${LIB_DIR}/acr.sh"

function usage() {
  cat <<EOF
Usage:
  ${0} [OPTIONS]

Options:
  --file     Path to image.yml
  --dry-run  Check for updates only; do not modify files
EOF
}

FILE=""
DRY_RUN=false

## Parse CLI args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file)
      FILE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[ERROR] Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

## Validate inputs
[[ -n "$FILE" ]] || { echo "[ERROR] --file is required" >&2; exit 1; }
[[ -f "$FILE" ]] || { echo "[ERROR] File not found: $FILE" >&2; exit 1; }

## Populate vars from image.yml
registry="$(yq e '.upstream.registry' "$FILE")"
name="$(yq e '.upstream.name' "$FILE")"
current="$(yq e '.upstream.version' "$FILE")"
version_arg_keys="$(yq e '.version_args | keys | .[]' "$FILE" 2>/dev/null || true)"

## Detect registry & latest version
case "$registry" in
  docker)
    latest="$(dockerhub_latest_version_tag "$name")"
    ;;
  ghcr)
    latest="$(ghcr_latest_version_tag "$name")"
    ;;
  gitlab)
    latest="$(gitlab_latest_version_tag "$name")"
    ;;
  acr)
    latest="$(acr_latest_version_tag "$name")"
    ;;
  manual)
    echo "Skipping manual image: $FILE"
    exit 0
    ;;
  *)
    echo "[ERROR] Unsupported upstream.registry: $registry" >&2
    exit 1
    ;;
esac

if [[ -z "${latest:-}" ]]; then
  echo "[ERROR] No tags found for $registry/$name" >&2
  exit 1
fi

if [[ "$latest" == "$current" ]]; then
  echo "Up to date: $name $current"
  exit 0
fi

echo "Update available: $name $current -> $latest"

if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY RUN] Detected image versions, but did not change any files. Run again without --dry-run to apply changes"
  exit 0
fi

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

update_expr=".upstream.version = \"$latest\""

## Read values & replace with new versions
while IFS= read -r key; do
  [[ -n "$key" ]] || continue
  update_expr+=" | .version_args.${key} = \"$latest\""
  update_expr+=" | .args.${key} = \"$latest\""
done <<< "$version_arg_keys"

## Write updates to temp file
yq e "$update_expr" "$FILE" > "$tmpfile"

## Overwrite old file with updated version
mv "$tmpfile" "$FILE"
trap - EXIT

echo "Updated $FILE"
