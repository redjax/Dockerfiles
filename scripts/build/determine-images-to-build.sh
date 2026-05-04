#!/usr/bin/env bash
set -euo pipefail

#################################################
# Scans the repository for image.yml manifests  #
# and compiles a list of images to build.       #
#                                               #
# Default behavior: only include images that    #
# appear changed since the last commit, unless  #
# --force is used.                              #
#################################################

build_list_file="${build_list.txt}"
force="${FORCE:-false}"
image_dir="${IMAGE_DIR:-}"

function usage() {
  cat <<EOF
Usage:
  $0 [OPTIONS] [OUTPUT_FILE]

Scans the repository for image.yml manifests and writes a list of image
directories that should be built.

By default, only images affected by recent git changes are included.
Use --force to include all publishable images.

Arguments:
  OUTPUT_FILE            Path to write the build list (default: build_list.txt)

Options:
  --force                Include all publishable images (ignore git changes)
  -f, --file PATH        Output file for build list (same as positional arg)
  --file=PATH            Same as above
  --image-dir PATH       Limit scan to a specific subdirectory
  -h, --help             Show this help message

Notes:
  - Only manifests with 'publish: true' are considered
  - Output contains directories, not image.yml file paths
  - Change detection includes:
    - image.yml changes
    - Dockerfile changes
    - build context changes
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      force="true"
      shift
      ;;
    -f|--file)
      build_list_file="${2:-}"
      shift 2
      ;;
    --file=*)
      build_list_file="${1#*=}"
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
    -*)
      echo "[ERROR] Invalid argument: $1" >&2
      usage
      exit 1
      ;;
    *)
      echo "[ERROR] Invalid argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

: > "$build_list_file"

function is_publishable_manifest() {
  local manifest="$1"
  [[ -f "$manifest" ]] || return 1
  
  local publish
  publish="$(yq e '.publish // false' "$manifest")"
  [[ "$publish" == "true" ]]
}

function manifest_to_dir() {
  dirname "$1"
}

if [[ "$force" == "true" ]]; then
  if [[ -n "$image_dir" ]]; then
    find "./$image_dir" -name image.yml -type f | sort | while IFS= read -r manifest; do
      is_publishable_manifest "$manifest" || continue
      manifest_to_dir "$manifest"
    done | sort -u > "$build_list_file"
  else
    find . -name image.yml -type f | sort | while IFS= read -r manifest; do
      is_publishable_manifest "$manifest" || continue
      manifest_to_dir "$manifest"
    done | sort -u > "$build_list_file"
  fi
else
  changed_files_file="$(mktemp)"
  trap 'rm -f "$changed_files_file"' EXIT

  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    git diff --name-only HEAD~1..HEAD > "$changed_files_file" 2>/dev/null || git ls-files > "$changed_files_file"
  else
    git ls-files > "$changed_files_file"
  fi

  if [[ -n "$image_dir" ]]; then
    search_root="./$image_dir"
  else
    search_root="."
  fi

  while IFS= read -r manifest; do
    [[ -n "$manifest" ]] || continue
    is_publishable_manifest "$manifest" || continue

    dir="$(dirname "$manifest")"
    dockerfile="$(yq e '.dockerfile // ""' "$manifest")"
    context="$(yq e '.context // ""' "$manifest")"

    if grep -Fxq "$manifest" "$changed_files_file"; then
      echo "$dir"
      continue
    fi

    [[ -n "$dockerfile" ]] && grep -Fxq "$dockerfile" "$changed_files_file" && { echo "$dir"; continue; }

    if [[ -n "$context" ]]; then
      if grep -Fxq "$context" "$changed_files_file"; then
        echo "$dir"
        continue
      fi
      if grep -Fq "${context}/" "$changed_files_file"; then
        echo "$dir"
        continue
      fi
    fi
  done < <(find "$search_root" -name image.yml -type f | sort) | sort -u > "$build_list_file"
fi

if [[ ! -s "$build_list_file" ]]; then
  echo "No containers to build."
else
  echo "Containers to build:"
  cat "$build_list_file"
fi
