#!/usr/bin/env bash
set -uo pipefail

#############################################################
# Trim old GHCR container versions for published images.    #
#                                                           #
# The script takes no actions unless you pass --apply.      #
# You can use --keep to manually override how many versions #
# should be retained (default is 5).                        #
#                                                           #
# Note that the script takes a Github API token, which you  #
# should create on Github. The token should have the        #
# following permissions:                                    #
#   - repo                                                  #
#   - write:packages & read:packages                        #
#   - delete:packages                                       #
#                                                           #
# You can create an API key in your GitHub settings at:     #
#   https://github.com/settings/tokens/                     #
#                                                           #
#############################################################

for cmd in curl jq yq sort awk grep cut tr; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "[ERROR] missing dependency: $cmd" >&2
    exit 1
  }
done

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${THIS_DIR}/../.." && pwd)"

KEEP_VERSIONS="${KEEP_VERSIONS:-5}"
SCAN_PATH="${SCAN_PATH:-$REPO_ROOT}"
GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
GH_API_URL="${GH_API_URL:-https://api.github.com}"

[[ -n "$GH_TOKEN" ]] || { echo "[ERROR] GH_TOKEN required" >&2; exit 1; }
[[ -d "$SCAN_PATH" ]] || { echo "[ERROR] scan path not found: $SCAN_PATH" >&2; exit 1; }

APPLY="false"

function usage() {
  echo ""
  echo "Usage: $0 [OPTIONS]"
  echo "Description:"
  echo "  Scans container registry and removes all tags older than the most recent N,"
  echo "  where N is the value of --keep (default: 5)."
  echo ""
  echo "  By default, no action is taken, you must pass --apply to delete images."
  echo ""
  echo "Options:"
  echo "  --apply     Apply the changes (delete old images)"
  echo "  --keep N    Retain the most recent N images (default: 5)"
  echo "  -h, --help  Print this help menu"
  echo ""
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help)
      usage
      exit 0
      ;;
    --apply)
      APPLY="true"
      shift
      ;;
    --keep)
      KEEP_VERSIONS="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

## Ensure we print out what would happen if --apply is not specified
if [[ "$APPLY" == "false" ]]; then
  echo "[INFO] No action will be taken. Use --apply to delete old images."
  echo "[INFO] The following actions would have been taken:"
fi

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

mapfile -t manifests < <(find "$SCAN_PATH" -name image.yml -type f | sort)

if ((${#manifests[@]} == 0)); then
  echo "No image manifests found."
  exit 0
fi

for file in "${manifests[@]}"; do
(
  set +e  # isolate errors per image

  publish="$(yq e '.publish // false' "$file")"
  [[ "$publish" == "true" ]] || exit 0

  registry_path="$(yq e '.registry_path' "$file")"
  name="$(yq e '.name' "$file")"

  [[ "$registry_path" == ghcr.io/* ]] || exit 0

  IFS='|' read -r owner repo package <<<"$(parse_registry "$registry_path")"

  package_full="${repo}/${package}"
  package_encoded="$(url_encode "$package_full")"

  api_url="${GH_API_URL}/users/${owner}/packages/container/${package_encoded}/versions?per_page=100"

  echo ""
  echo "Checking ${name} (${owner}/${repo}/${package})"
  # echo "DEBUG: $api_url"
  echo

  versions_json="$(gh_api "$api_url" || true)"

  if [[ -z "${versions_json}" || "${versions_json}" == "null" ]]; then
    echo "  [WARN] failed to fetch versions"
    exit 0
  fi

  mapfile -t version_rows < <(
    jq -r '
      .[]
      | [
          (.id|tostring),
          (.name // ""),
          ((.metadata.container.tags // []) | join(",")),
          (.created_at // "")
        ]
      | @tsv
    ' <<<"$versions_json" \
    | sort -t $'\t' -k4,4r
  )

  kept=0

  for row in "${version_rows[@]}"; do
    IFS=$'\t' read -r version_id version_name tags_csv created_at <<<"$row"

    tags_display="${tags_csv:-<no-tags>}"

    ## Always keep latest
    if [[ "$tags_csv" == *"latest"* ]]; then
      echo "  keep:   $version_id $version_name [$tags_display] (latest)"
      continue
    fi

    ## keep newest N others
    if (( kept < KEEP_VERSIONS )); then
      echo "  keep:   $version_id $version_name [$tags_display]"
      ((kept++))
      continue
    fi

    ## delete everything else
    if [[ "$APPLY" == "true" ]]; then
      echo "  deleting: $version_id $version_name [$tags_display]"
      gh_api_delete \
        "${GH_API_URL}/users/${owner}/packages/container/${package_encoded}/versions/${version_id}" \
        || echo "  [WARN] delete failed"
    else
      echo "  would delete: $version_id $version_name [$tags_display]"
    fi
  done

  set -e
) || {
  echo "[WARN] failed processing $(basename "$file"), continuing"
}
done
