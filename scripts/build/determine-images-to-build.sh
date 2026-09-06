#!/usr/bin/env bash
set -euo pipefail

############################################################
# Determine which container images need to be built.       #
#                                                          #
# Each image must have the following files:                #
#                                                          #
#   - Dockerfile                                           #
#   - metadata.yml                                         #
#   - README.md                                            #
#                                                          #
# The script compares changed Git files against image      #
# directories. Any file changed below an image directory   #
# causes that image to be selected.                        #
#                                                          #
# The output file contains one image directory per line.   #
############################################################

image_root="${IMAGE_ROOT:-dockerfiles}"
output_file="${OUTPUT_FILE:-build_list.txt}"
force="${FORCE:-false}"
base_ref="${BASE_REF:-}"
head_ref="${HEAD_REF:-HEAD}"

function usage() {
  cat <<EOF
Usage:
  ${0##*/} [OPTIONS]

Options:
  --image-root  PATH  Root directory containing Dockerfiles. Default: dockerfiles
  --output      PATH  Output file containing image directories. Default: build_list.txt
  --base        REF   Git base revision used for change detection.
  --head        REF   Git head revision used for change detection. Default: HEAD
  --force             Select every image instead of checking changes.
  -h, --help          Show this help message.

Examples:
  ${0##*/} --outpt
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --image-root)
    image_root="${2:-}"
    shift 2
    ;;
  --image-root=*)
    image_root="${1#*=}"
    shift
    ;;
  --output)
    output_file="${2:-}"
    shift 2
    ;;
  --output=*)
    output_file="${1#*=}"
    shift
    ;;
  --base)
    base_ref="${2:-}"
    shift 2
    ;;
  --base=*)
    base_ref="${1#*=}"
    shift
    ;;
  --head)
    head_ref="${2:-}"
    shift 2
    ;;
  --head=*)
    head_ref="${1#*=}"
    shift
    ;;
  --force)
    force="true"
    shift
    ;;
  -h | --help)
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

[[ -d "$image_root" ]] || {
  echo "[ERROR] Image root does not exist: $image_root" >&2
  exit 1
}

## Find every directory that represents a buildable image.
#  A valid image directory must contain both Dockerfile and metadata.yml.
mapfile -t image_dirs < <(
  find "$image_root" \
    -type f \
    -name Dockerfile \
    -exec dirname {} \; |
    while IFS= read -r image_dir; do
      [[ -f "$image_dir/metadata.yml" ]] || {
        echo "[WARN] Skipping $image_dir: missing metadata.yml" >&2
        continue
      }

      printf '%s\n' "$image_dir"
    done |
    sort -u
)

[[ "${#image_dirs[@]}" -gt 0 ]] || {
  echo "[ERROR] No valid images found below: $image_root" >&2
  exit 1
}

## Force mode selects every discovered image.
if [[ "$force" == "true" ]]; then
  printf '%s\n' "${image_dirs[@]}" | sort -u >"$output_file"

  echo "Force mode enabled."
  echo "Images to build:"
  cat "$output_file"

  exit 0
fi

## Determine the Git base revision if one was not supplied.
if [[ -z "$base_ref" ]]; then
  if git rev-parse --verify HEAD^ >/dev/null 2>&1; then
    base_ref="$(git rev-parse HEAD^)"
  else
    echo "[ERROR] Unable to determine Git base revision." >&2
    echo "        Pass --base REF or use --force." >&2
    exit 1
  fi
fi

## Store the changed-file list separately from the output list.
#  The output file will be replaced later with image directories.
changed_files_file="$(mktemp)"
selected_images_file="$(mktemp)"

function cleanup() {
  rm -f "$changed_files_file"
  rm -f "$selected_images_file"
}

trap cleanup EXIT

## Determine changed files between the base and head revisions.
git diff --name-only "$base_ref" "$head_ref" >"$changed_files_file"

echo "Changed files:"
if [[ -s "$changed_files_file" ]]; then
  cat "$changed_files_file"
else
  echo "  <none>"
fi

## Select an image when any file below its directory changed.
: >"$selected_images_file"

for image_dir in "${image_dirs[@]}"; do
  while IFS= read -r changed_file; do
    [[ -n "$changed_file" ]] || continue

    case "$changed_file" in
    "$image_dir"/*)
      echo "$image_dir" >>"$selected_images_file"
      break
      ;;
    esac
  done <"$changed_files_file"
done

## Remove duplicate image directories and write the final build list.
sort -u "$selected_images_file" >"$output_file"

echo
echo "Images to build:"

if [[ -s "$output_file" ]]; then
  cat "$output_file"
else
  echo "  <none>"
fi
