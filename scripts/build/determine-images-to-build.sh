#!/usr/bin/env bash
set -euo pipefail

build_list_file="build_list.txt"
force="${FORCE:-false}"
image_dir="${IMAGE_DIR:-}"

function usage() {
  cat <<EOF
Usage:
  $0 [OPTIONS] [OUTPUT_FILE]

Options:
  --force
  --image-dir PATH
  -h, --help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force="true"
      shift
      ;;
    --image-dir)
      image_dir="${2:-}"
      shift 2
      ;;
    --image-dir=*)
      image_dir="${1#*=}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      build_list_file="$1"
      shift
      ;;
  esac
done

: > "$build_list_file"

function is_publishable() {
  local manifest="$1"
  [[ "$(yq e '.publish // false' "$manifest")" == "true" ]]
}

function get_registry_ref() {
  local manifest="$1"
  local registry_path tag
  registry_path="$(yq e '.registry_path' "$manifest")"
  tag="$(yq e '.upstream.version' "$manifest")"
  echo "${registry_path}:${tag}"
}

function manifest_dir() {
  dirname "$1"
}

function image_exists_remote() {
  local ref="$1"

  ## failure = treat as "does not exist"
  docker buildx imagetools inspect "$ref" >/dev/null 2>&1
}

function changed_by_git() {
  local manifest="$1"
  local dockerfile context changed_file

  dockerfile="$(yq e '.dockerfile // ""' "$manifest")"
  context="$(yq e '.context // ""' "$manifest")"

  grep -Fxq "$manifest" ${build_list_file} && return 0
  [[ -n "$dockerfile" ]] && grep -Fxq "$dockerfile" ${build_list_file} && return 0

  if [[ -n "$context" ]]; then
    grep -Fxq "$context" ${build_list_file} && return 0
    grep -Fq "${context}/" ${build_list_file} && return 0
  fi

  return 1
}

## Build changed files list
changed_files_file="${build_list_file}"
if [[ "$force" == "false" ]]; then
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    git diff --name-only HEAD~1..HEAD > "$changed_files_file" 2>/dev/null || true
  else
    git ls-files > "$changed_files_file"
  fi
else
  : > "$changed_files_file"
fi

search_root="."
[[ -n "$image_dir" ]] && search_root="./$image_dir"

mapfile -t manifests < <(find "$search_root" -name image.yml -type f | sort)

for manifest in "${manifests[@]}"; do
(
  set +e

  is_publishable "$manifest" || exit 0

  dir="$(manifest_dir "$manifest")"
  registry_ref="$(get_registry_ref "$manifest")"

  publish_reason=""

  ## Force mode
  if [[ "$force" == "true" ]]; then
    echo "$dir"
    exit 0
  fi

  ## First publish/new image
  if ! image_exists_remote "$registry_ref"; then
    publish_reason="first publish (missing remote image)"
    echo "$dir"
    exit 0
  fi

  ## Normal change detection
  if changed_by_git "$manifest"; then
    publish_reason="git changes detected"
    echo "$dir"
    exit 0
  fi

) || {
  echo "[WARN] failed processing $manifest"
}
done | sort -u > "$build_list_file"

if [[ ! -s "$build_list_file" ]]; then
  echo "No containers to build."
else
  echo "Containers to build:"
  cat "$build_list_file"
fi
