#!/usr/bin/env bash
set -euo pipefail

#################################################
# Scans the repository for image.yml manifests  #
# and compiles a list of images to build.       #
#                                               #
# Only finds images where `publish: true`.      #
#################################################

build_list_file="${1:-build_list.txt}"

## Open the build list file to write detected manifests to
: > "$build_list_file"

if [[ -n "${IMAGE_DIR:-}" ]]; then
  ## Only search for images in given directory
  echo "$IMAGE_DIR" > "$build_list_file"
else
  ## Find all image.yml manifests
  find . -name image.yml -type f | sort | while IFS= read -r manifest; do
    [[ -n "$manifest" ]] || continue

    publish="$(yq e '.publish' "$manifest")"
    [[ "$publish" == "true" ]] || continue

    dirname "$manifest"
  done | sort -u > "$build_list_file"
fi

if [[ ! -s "$build_list_file" ]]; then
  echo "No containers to build."
else
  echo "Containers to build:"
  cat "$build_list_file"
fi
