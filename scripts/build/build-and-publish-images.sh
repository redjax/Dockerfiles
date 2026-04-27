#!/usr/bin/env bash
set -euo pipefail

####################################################
# Build and publish containers that have changed.  #
#                                                  #
# Note: this script looks for a build_list.txt     #
# file that has the paths to containers that need  #
# (re)building.                                    #
#                                                  #
# This file is the output of:                      # 
#   scripts/build/determine-images-to-build.sh     #
####################################################

build_list_file="build_list.txt"
dry_run="${DRY_RUN:-false}"

## Parse CLI args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run="true"
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
    -*)
      echo "[ERROR] Unknown option: $1" >&2
      exit 1
      ;;
    *)
      build_list_file="$1"
      shift
      ;;
  esac
done

## Get shorthash from pipeline/env var, or from git rev-parse
short_sha="${GITHUB_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo local)}"
short_sha="${short_sha:0:7}"

## Check for build manifest file
[[ -f "$build_list_file" ]] || { echo "[ERROR] Missing build list: $build_list_file" >&2; exit 1; }

## Ensure file is not empty
if [[ ! -s "$build_list_file" ]]; then
  echo "No containers to build."
  exit 0
fi

## Find publishable images & read manifest
while IFS= read -r image_dir; do
  [[ -n "$image_dir" ]] || continue

  manifest="$image_dir/image.yml"
  [[ -f "$manifest" ]] || continue

  ## Check if publish: true in image.yml
  publish="$(yq e '.publish' "$manifest")"
  [[ "$publish" == "true" ]] || continue

  ## Populate vars from image.yml
  context="$(yq e '.context' "$manifest")"
  dockerfile="$(yq e '.dockerfile' "$manifest")"
  name="$(yq e '.name' "$manifest")"
  registry_path="$(yq e '.registry_path' "$manifest")"
  tag="$(yq e '.upstream.version' "$manifest")"

  ## Read build args from image.yml
  build_args=()
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    value="$(yq e ".args.${key}" "$manifest")"
    [[ -n "$value" && "$value" != "null" ]] || continue
    build_args+=(--build-arg "${key}=${value}")
  done < <(yq e '.args | keys | .[]' "$manifest" 2>/dev/null || true)

  echo ""
  echo "Building $name from $manifest"

  if [[ "$dry_run" == "true" ]]; then
    echo "[DRY RUN] ./scripts/build/build-image.sh --context $context --dockerfile $dockerfile --name $name --tag $tag ${build_args[*]}"
    echo "[DRY RUN] docker tag ${name}:${tag} ${registry_path}:${tag}"
    echo "[DRY RUN] docker tag ${name}:${tag} ${registry_path}:latest"
    echo "[DRY RUN] docker tag ${name}:${tag} ${registry_path}:${short_sha}"
    echo "[DRY RUN] docker push ${registry_path}:${tag}"
    echo "[DRY RUN] docker push ${registry_path}:latest"
    echo "[DRY RUN] docker push ${registry_path}:${short_sha}"
  else
    ## Build container image
    ./scripts/build/build-image.sh \
      --context "$context" \
      --dockerfile "$dockerfile" \
      --name "$name" \
      --tag "$tag" \
      "${build_args[@]}"

    ## Tag image
    docker tag "${name}:${tag}" "${registry_path}:${tag}"
    docker tag "${name}:${tag}" "${registry_path}:latest"
    docker tag "${name}:${tag}" "${registry_path}:${short_sha}"

    ## Publish to registry
    docker push "${registry_path}:${tag}"
    docker push "${registry_path}:latest"
    docker push "${registry_path}:${short_sha}"
  fi
done < "$build_list_file"
