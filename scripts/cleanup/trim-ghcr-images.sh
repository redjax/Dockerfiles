#!/usr/bin/env bash
set -euo pipefail

############################################################
# Trim old GHCR container versions for published images.   #
#                                                          #
# The script takes no actions unless you pass --apply.     #
# Note that the script takes a Github API token, which you #
# should create on Github. The token should have the       #
# following permissions:                                   #
#   - repo                                                 #
#   - write:packages & read:packages                       #
#   - delete:packages                                      #
#                                                          #
# You can create an API key in your Github settings at:    #
#   https://github.com/settings/tokens/                    #
#                                                          #
############################################################

for cmd in curl jq yq sort awk grep cut tr; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "[ERROR] missing dependency: $cmd" >&2
    exit 1
  }
done

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${THIS_DIR}/../.." && pwd)"

KEEP_VERSIONS="${KEEP_VERSIONS:-5}"
DRY_RUN="${DRY_RUN:-true}"
SCAN_PATH="${SCAN_PATH:-$REPO_ROOT}"
GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
GH_API_URL="${GH_API_URL:-https://api.github.com}"

[[ -n "$GH_TOKEN" ]] || { echo "[ERROR] GH_TOKEN required" >&2; exit 1; }
[[ -d "$SCAN_PATH" ]] || { echo "[ERROR] scan path not found: $SCAN_PATH" >&2; exit 1; }

function gh_api() {
  curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$1"
}

function gh_api_delete() {
  curl -fsSL \
    -X DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$1" >/dev/null
}

function url_encode() {
  jq -rn --arg v "$1" '$v|@uri'
}

function parse_registry() {
  local input="$1"

  local path="${input#ghcr.io/}"

  local owner="${path%%/*}"
  local repo="${path#*/}"
  repo="${repo%%/*}"

  local package="${path##*/}"

  echo "$owner|$repo|$package"
}

function keep_version() {
  local name="$1"
  local tags="$2"

  [[ "$name" == "latest" ]] && return 0
  [[ "$tags" == *"latest"* ]] && return 0
  return 1
}

## Find manifests
mapfile -t manifests < <(find "$SCAN_PATH" -name image.yml -type f | sort)

if ((${#manifests[@]} == 0)); then
  echo "No image manifests found."
  exit 0
fi

## Loop over manifests & build registry path, then scan container registry
#  for images/tags to delete
for file in "${manifests[@]}"; do
  publish="$(yq e '.publish // false' "$file")"
  [[ "$publish" == "true" ]] || continue

  registry_path="$(yq e '.registry_path' "$file")"
  name="$(yq e '.name' "$file")"

  [[ -n "$registry_path" && "$registry_path" != "null" ]] || continue
  [[ "$registry_path" == ghcr.io/* ]] || continue

  IFS='|' read -r owner repo package <<<"$(parse_registry "$registry_path")"

  package_encoded="$(url_encode "$package")"

  echo ""
  echo "Checking ${name} (${owner}/${repo}/${package})"

  package_full="${repo}/${package}"

  package_encoded="$(url_encode "$package_full")"

  api_url="${GH_API_URL}/users/${owner}/packages/container/${package_encoded}/versions?per_page=100"

  # echo "DEBUG: $api_url"

  versions_json="$(gh_api "$api_url")"

  mapfile -t version_rows < <(
    jq -r '
      .[]
      | [
          (.id|tostring),
          (.name // ""),
          ((.metadata.container.tags // []) | join(",")),
          (.created_at // ""),
          (.updated_at // "")
        ]
      | @tsv
    ' <<<"$versions_json" \
    | sort -t $'\t' -k4,4r -k5,5r
  )

  if ((${#version_rows[@]} == 0)); then
    echo "  No versions found."
    continue
  fi

  kept=0

  for row in "${version_rows[@]}"; do
    IFS=$'\t' read -r version_id version_name tags_csv created_at updated_at <<<"$row"

    if keep_version "$version_name" "$tags_csv" || (( kept < KEEP_VERSIONS )); then
      echo "  keep: ${version_id} ${version_name} [${tags_csv}]"
      ((kept++))
      continue
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
      echo "  dry-run delete: ${version_id} ${version_name} [${tags_csv}]"
    else
      echo "  deleting: ${version_id} ${version_name} [${tags_csv}]"
      gh_api_delete \
        "${GH_API_URL}/repos/${owner}/${repo}/packages/container/${package_encoded}/versions/${version_id}"
    fi
  done
done