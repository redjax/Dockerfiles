#!/usr/bin/env bash
set -euo pipefail

####################################################
# Build and publish containers that have changed.  #
#                                                  #
# Default behavior: build locally, compare the     #
# built image digest to the remote tag digest, and #
# only publish if different.                       #
#                                                  #
# Use --force to always publish.                   #
####################################################

build_list_file="build_list.txt"
dry_run="${DRY_RUN:-false}"
force="${FORCE:-false}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run="true"
      shift
      ;;
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

get_remote_digest() {
  local ref="$1"
  docker buildx imagetools inspect "$ref" --format '{{.Manifest.Digest}}' 2>/dev/null || true
}

get_local_digest() {
  local image_ref="$1"
  docker image inspect "$image_ref" --format '{{index .RepoDigests 0}}' 2>/dev/null | awk -F@ '{print $2}' || true
}

while IFS= read -r image_dir; do
  [[ -n "$image_dir" ]] || continue

  manifest="$image_dir/image.yml"
  [[ -f "$manifest" ]] || continue

  publish="$(yq e '.publish // false' "$manifest")"
  [[ "$publish" == "true" ]] || continue

  ## Populate vars from image.yml
  context="$(yq e '.context' "$manifest")"
  dockerfile="$(yq e '.dockerfile' "$manifest")"
  name="$(yq e '.name' "$manifest")"
  registry_path="$(yq e '.registry_path' "$manifest")"
  tag="$(yq e '.upstream.version' "$manifest")"

  ## Read build args from image.yml
  declare -A build_args_map
  build_args=()
  
  ## Base args
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    value="$(yq e ".args.${key}" "$manifest")"
    [[ -n "$value" && "$value" != "null" ]] || continue
    build_args_map["$key"]="$value"
  done < <(yq e '.args | keys | .[]' "$manifest" 2>/dev/null || true)

  ## version_args override
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    value="$(yq e ".version_args.${key}" "$manifest")"
    [[ -n "$value" && "$value" != "null" ]] || continue
    build_args_map["$key"]="$value"
  done < <(yq e '.version_args | keys | .[]' "$manifest" 2>/dev/null || true)

  ## Convert map to CLI args
  for key in "${!build_args_map[@]}"; do
    build_args+=(--build-arg "${key}=${build_args_map[$key]}")
  done

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
    continue
  fi

  remote_digest=""
  if [[ "$force" != "true" ]]; then
    remote_digest="$(get_remote_digest "${registry_path}:${tag}")"
    if [[ -n "$remote_digest" ]]; then
      echo "Remote digest for ${registry_path}:${tag}: $remote_digest"
    else
      echo "Remote digest for ${registry_path}:${tag}: <not found>"
    fi
  fi

  ./scripts/build/build-image.sh \
    --context "$context" \
    --dockerfile "$dockerfile" \
    --name "$name" \
    --tag "$tag" \
    "${build_args[@]}"

  local_digest="$(get_local_digest "${name}:${tag}")"
  if [[ -n "$local_digest" ]]; then
    echo "Local digest for ${name}:${tag}: $local_digest"
  else
    echo "Local digest for ${name}:${tag}: <not found>"
  fi

  if [[ "$force" != "true" && -n "$remote_digest" && -n "$local_digest" && "$remote_digest" == "$local_digest" ]]; then
    echo "Skipping publish for ${name}:${tag}; image is unchanged."
    continue
  fi

  docker tag "${name}:${tag}" "${registry_path}:${tag}"
  docker tag "${name}:${tag}" "${registry_path}:latest"
  docker tag "${name}:${tag}" "${registry_path}:${short_sha}"

  docker push "${registry_path}:${tag}"
  docker push "${registry_path}:latest"
  docker push "${registry_path}:${short_sha}"
done < "$build_list_file"
