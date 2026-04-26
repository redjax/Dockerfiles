#!/usr/bin/env bash
set -euo pipefail

########################################################
# Bump a Dockerfile's ARG containing the image tag.    #
#                                                      #
# Uses a container's image.yml manifest to check if    #
# a newer tag is available and updates the ARG value.  #
########################################################

## Check for missing dependencies
for cmd in yq awk mktemp grep sed diff; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[ERROR] $cmd is not installed" >&2; exit 1; }
done

function usage() {
  cat <<EOF
Usage:
  $0 [OPTIONS]

Updates Dockerfile ARG defaults from image.yml version_args.

Options:
  --file      Path to an image.yml file
  --dry-run   Describe actions without taking them
  -h, --help  Show this help menu
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

## Find Dockerfile in image.yml's path
dockerfile_rel="$(yq e '.dockerfile' "$FILE")"
[[ -n "$dockerfile_rel" && "$dockerfile_rel" != "null" ]] || { echo "[ERROR] .dockerfile missing in $FILE" >&2; exit 1; }

## Populate vars
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
dockerfile_path="$repo_root/$dockerfile_rel"

## Test Dockerfile path
[[ -f "$dockerfile_path" ]] || { echo "[ERROR] Dockerfile not found: $dockerfile_path" >&2; exit 1; }

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

## Copy existing Dockerfile for safe manipulation
cp "$dockerfile_path" "$tmpfile"

changed=false

## Check if version needs bumped
while IFS= read -r key; do
  [[ -n "$key" ]] || continue

  value="$(yq e ".version_args.${key}" "$FILE")"
  [[ -n "$value" && "$value" != "null" ]] || continue

  line="$(grep -E "^ARG[[:space:]]+${key}=" "$tmpfile" | head -n1 || true)"
  [[ -n "$line" ]] || continue

  current_value="${line#ARG ${key}=}"

  if [[ "$current_value" != "$value" ]]; then
    sed -i "s|^ARG[[:space:]]\+${key}=.*$|ARG ${key}=${value}|" "$tmpfile"
    changed=true
  fi
done < <(yq e '.version_args | keys | .[]' "$FILE" 2>/dev/null || true)

## No change
if [[ "$changed" != true ]]; then
  echo "Up to date: $dockerfile_path"
  exit 0
fi

## Show changes in dry run mode
if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY RUN] Would update $dockerfile_path"
  diff -u "$dockerfile_path" "$tmpfile" || true
  exit 0
fi

## Overwrite Dockerfile with changes
mv "$tmpfile" "$dockerfile_path"
trap - EXIT
echo "Updated $dockerfile_path"
