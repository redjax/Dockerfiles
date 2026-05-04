#!/usr/bin/env bash
set -euo pipefail

################################################
# Bump image tags + sync version args          #
#                                              #
# This script reads a given image.yml file,    #
# checks for new versions of upstream images,  #
# and updates:                                 #
#   - upstream.version                         #
#   - version_args                             #
#   - args (to match version_args)             #
#                                              #
# It will also fix drift where args !=         #
# version_args even if upstream did not change #
################################################

GH_TOKEN="${GITHUB_TOKEN:-}"

function usage() {
  cat <<EOF
Usage:
  ${0} --file PATH [OPTIONS]

Options:
  --file PATH          Path to image.yml (required)
  --dry-run            Check for updates only; do not modify files
  --github-token TOKEN GitHub token (or set GITHUB_TOKEN env var)
  -h, --help           Show this help menu
EOF
}

## Get latest upstream version from registry
function get_latest_version() {
  local registry="$1"
  local name="$2"
  local track="$3"

  case "$registry" in
    docker)
      dockerhub_latest_version_tag "$name" "$track"
      ;;
    ghcr)
      ghcr_latest_version_tag "$name" "$track"
      ;;
    gitlab)
      gitlab_latest_version_tag "$name" "$track"
      ;;
    acr)
      acr_latest_version_tag "$name" "$track"
      ;;
    manual)
      ## No automatic updates
      echo ""
      ;;
    *)
      echo "[ERROR] Unsupported upstream.registry: $registry" >&2
      exit 1
      ;;
  esac
}

## Ensure required dependencies exist
for cmd in curl yq jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[ERROR] $cmd is not installed" >&2
    exit 1
  fi
done

## Load registry helper libraries
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${THIS_DIR}/lib"

source "${LIB_DIR}/components.sh"
source "${LIB_DIR}/tag_utils.sh"
source "${LIB_DIR}/dockerhub.sh"
source "${LIB_DIR}/ghcr.sh"
source "${LIB_DIR}/gitlab.sh"
source "${LIB_DIR}/acr.sh"

## Parse CLI arguments
FILE=""
DRY_RUN=false
GH_TOKEN="${GITHUB_TOKEN:-}"

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
    --github-token)
      GH_TOKEN="$2"
      shift 2
      ;;
    --github-token=*)
      GH_TOKEN="${1#*=}"
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

## Validate input
[[ -n "$FILE" ]] || { echo "[ERROR] --file is required" >&2; exit 1; }
[[ -f "$FILE" ]] || { echo "[ERROR] File not found: $FILE" >&2; exit 1; }

## Read manifest fields
registry="$(yq e '.upstream.registry' "$FILE")"
name="$(yq e '.upstream.name' "$FILE")"
track="$(yq e '.upstream.track' "$FILE")"
current="$(yq e '.upstream.version' "$FILE")"

[[ -n "$registry" && "$registry" != "null" ]] || { echo "[ERROR] .upstream.registry missing in $FILE" >&2; exit 1; }
[[ -n "$name" && "$name" != "null" ]] || { echo "[ERROR] .upstream.name missing in $FILE" >&2; exit 1; }
[[ -n "$track" && "$track" != "null" ]] || { echo "[ERROR] .upstream.track missing in $FILE" >&2; exit 1; }
[[ -n "$current" && "$current" != "null" ]] || { echo "[ERROR] .upstream.version missing in $FILE" >&2; exit 1; }

## Determine latest upstream version
latest="$(get_latest_version "$registry" "$name" "$track")"

if [[ -z "${latest:-}" ]]; then
  echo "[ERROR] No tags found for $registry/$name ($track)" >&2
  exit 1
fi

## Detect whether update is needed
needs_update=false
reason=""

## Check upstream version drift
if [[ "$latest" != "$current" ]]; then
  needs_update=true
  reason="upstream version changed ($current -> $latest)"
fi

## Check args drift vs version_args
while IFS= read -r key; do
  [[ -n "$key" ]] || continue

  version_val="$(yq e ".version_args.${key}" "$FILE")"
  args_val="$(yq e ".args.${key}" "$FILE")"

  if [[ "$version_val" != "$args_val" ]]; then
    needs_update=true
    reason="${reason:+$reason, }args drift (${key}: ${args_val} -> ${version_val})"
  fi
done < <(yq e '.version_args | keys | .[]' "$FILE" 2>/dev/null || true)

## Process components
while IFS= read -r component; do
  [[ -n "$component" ]] || continue

  type="$(yq e ".components.${component}.type" "$FILE")"
  track="$(yq e ".components.${component}.track" "$FILE")"
  current_comp="$(yq e ".components.${component}.version" "$FILE")"

  [[ -z "$type" || "$type" == "null" ]] && continue

  identifier=""

  case "$type" in
    dockerhub)
      identifier="$(yq e ".components.${component}.name" "$FILE")"
      ;;
    github_release)
      identifier="$(yq e ".components.${component}.repo" "$FILE")"
      ;;
  esac

  latest_comp="$(resolve_component_version "$type" "$identifier" "$track")"

  if [[ -z "$latest_comp" || "$latest_comp" == "null" ]]; then
    continue
  fi

  if [[ "$latest_comp" != "$current_comp" ]]; then
    echo "Updating component ${component}: ${current_comp} -> ${latest_comp}"
    needs_update=true
    reason="${reason:+$reason, }component ${component} updated"
  fi

done < <(yq e '.components | keys | .[]' "$FILE" 2>/dev/null || true)

## Exit early if no update needed
if [[ "$needs_update" == false ]]; then
  echo "Up to date: $name $current"
  exit 0
fi

echo "Update needed: $name ($reason)"

if [[ "$DRY_RUN" == true ]]; then
  echo "[DRY RUN] No files modified"
  exit 0
fi

## Build yq update expression
tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

## Always update upstream version
update_expr=".upstream.version = \"$latest\""

## Sync version_args & args
while IFS= read -r key; do
  [[ -n "$key" ]] || continue

  version_val="$(yq e ".version_args.${key}" "$FILE")"

  update_expr+=" | .version_args.${key} = \"${version_val}\" | .args.${key} = \"${version_val}\""
done < <(yq e '.version_args | keys | .[]' "$FILE" 2>/dev/null || true)

## Apply component updates + sync args if mapped
while IFS= read -r component; do
  [[ -n "$component" ]] || continue

  type="$(yq e ".components.${component}.type" "$FILE")"
  track="$(yq e ".components.${component}.track" "$FILE")"

  identifier=""
  case "$type" in
    dockerhub)
      identifier="$(yq e ".components.${component}.name" "$FILE")"
      ;;
    github_release)
      identifier="$(yq e ".components.${component}.repo" "$FILE")"
      ;;
  esac

  latest_comp="$(resolve_component_version "$type" "$identifier" "$track")"

  if [[ -n "$latest_comp" && "$latest_comp" != "null" ]]; then
    update_expr+=" | .components.${component}.version = \"${latest_comp}\""

    arg="$(yq e ".components.${component}.arg" "$FILE")"
    if [[ -n "$arg" && "$arg" != "null" ]]; then
      update_expr+=" | .version_args.${arg} = \"${latest_comp}\" | .args.${arg} = \"${latest_comp}\""
    fi
  fi

done < <(yq e '.components | keys | .[]' "$FILE" 2>/dev/null || true)

## Apply update
yq e "$update_expr" "$FILE" > "$tmpfile"
mv "$tmpfile" "$FILE"
trap - EXIT

echo "Updated $FILE"
