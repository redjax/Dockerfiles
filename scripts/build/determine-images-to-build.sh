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
  -h | --help)
    usage
    exit 0
    ;;
  *)
    build_list_file="$1"
    shift
    ;;
  esac
done

[[ -f "$build_list_file" ]] || {
  echo "[ERROR] Missing build list: $build_list_file" >&2
  exit 1
}

function is_publishable() {
  local manifest="$1"

  [[ "$(yq e '.publish // false' "$manifest")" == "true" ]]
}

function get_registry_ref() {
  local manifest="$1"
  local registry_path
  local tag

  registry_path="$(yq e '.registry_path' "$manifest")"
  tag="$(yq e '.upstream.version' "$manifest")"

  echo "${registry_path}:${tag}"
}

function manifest_dir() {
  dirname "$1"
}

function image_exists_remote() {
  local ref="$1"

  ## Treat failures as "does not exist"
  docker buildx imagetools inspect "$ref" >/dev/null 2>&1
}

function changed_by_git() {
  local manifest="$1"
  local changed_files="$2"
  local dockerfile
  local context
  local manifest_rel
  local dockerfile_rel

  ## Normalize paths so Git paths and find paths are compared consistently.
  manifest_rel="${manifest#./}"

  dockerfile="$(yq e '.dockerfile // ""' "$manifest")"
  context="$(yq e '.context // ""' "$manifest")"

  dockerfile="${dockerfile#./}"
  context="${context#./}"

  ## image.yml itself changed
  if grep -Fxq "$manifest_rel" "$changed_files"; then
    return 0
  fi

  ## Dockerfile changed
  if [[ -n "$dockerfile" ]] && grep -Fxq "$dockerfile" "$changed_files"; then
    return 0
  fi

  ## If dockerfile is relative to the build context, check that path too.
  if [[ -n "$dockerfile" && -n "$context" ]]; then
    dockerfile_rel="${context%/}/${dockerfile#./}"

    if grep -Fxq "$dockerfile_rel" "$changed_files"; then
      return 0
    fi
  fi

  ## Anything under the build context changed
  if [[ -n "$context" ]]; then
    if grep -Fxq "$context" "$changed_files"; then
      return 0
    fi

    if grep -Fq "${context%/}/" "$changed_files"; then
      return 0
    fi
  fi

  return 1
}

## Preserve the incoming changed-file list before replacing it
changed_files_file="$(mktemp)"

cleanup() {
  rm -f "$changed_files_file"
}

trap cleanup EXIT

cp "$build_list_file" "$changed_files_file"

## The output file is now rebuilt as a list of image directories.
: >"$build_list_file"

echo "Changed files:"
if [[ -s "$changed_files_file" ]]; then
  cat "$changed_files_file"
else
  echo "  <none>"
fi

echo ""

search_root="."
[[ -n "$image_dir" ]] && search_root="./$image_dir"

mapfile -t manifests < <(
  find "$search_root" -name image.yml -type f -print | sed 's#^\./##' | sort
)

for manifest in "${manifests[@]}"; do
  (
    set +e

    is_publishable "$manifest" || exit 0

    dir="$(manifest_dir "$manifest")"
    registry_ref="$(get_registry_ref "$manifest")"

    ## Force mode
    if [[ "$force" == "true" ]]; then
      echo "$dir"
      exit 0
    fi

    ## First publish/new image
    if ! image_exists_remote "$registry_ref"; then
      echo "$dir"
      exit 0
    fi

    echo "Checking manifest: $manifest"
    echo "  dockerfile: $(yq e '.dockerfile // ""' "$manifest")"
    echo "  context:    $(yq e '.context // ""' "$manifest")"

    ## Normal change detection
    if changed_by_git "$manifest" "$changed_files_file"; then
      echo "$dir"
      exit 0
    fi
  ) || {
    echo "[WARN] failed processing $manifest" >&2
  }
done | sort -u >"$build_list_file"

echo ""

if [[ ! -s "$build_list_file" ]]; then
  echo "No containers to build."
else
  echo "Containers to build:"
  cat "$build_list_file"
fi
