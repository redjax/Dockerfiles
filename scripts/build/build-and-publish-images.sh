#!/usr/bin/env bash
set -euo pipefail

############################################################
# Build and publish changed container images.              #
#                                                          #
# The input file contains one image directory per line:    #
#                                                          #
#   dockerfiles/base/alpine                                #
#   dockerfiles/iac/terraform                              #
#                                                          #
# Each image directory must contain:                       #
#                                                          #
#   Dockerfile                                             #
#   metadata.yml                                           #
#                                                          #
# metadata.yml contains only static image metadata.        #
# Dependency versions remain in Dockerfile ARG values and  #
# are updated by Renovate.                                 #
#                                                          #
# Images receive the following tags:                       #
#                                                          #
#   :latest                                                #
#   :<short-git-sha>                                       #
#                                                          #
# Publishing is disabled by default.                       #
############################################################

build_list_file="build_list.txt"
dry_run="${DRY_RUN:-false}"
enable_publishing="${PUBLISH:-false}"
pull_images="${PULL:-false}"

function usage() {
  cat <<EOF
Usage:
  ${0##*/} [OPTIONS] [BUILD_LIST_FILE]

Description:
  Builds and optionally publishes images listed in a build list file.

Arguments:
  BUILD_LIST_FILE
      File containing one image directory per line.
      Default: build_list.txt.

Options:
  --dry-run           Print build and publish commands without executing them.
  -f, --file PATH     Path to the build list file.
  --file=PATH         Same as --file PATH.
  -P, --publish       Enable publishing to the container registry.
  --pull              Always pull base images before building.
  -h, --help          Show this help message.

Environment:
  DRY_RUN=true
      Equivalent to --dry-run.

  PUBLISH=true
      Enable publishing.

  PULL=true
      Always pull base images.

  GITHUB_SHA
      Used to generate the immutable image tag.

  IMAGE_SOURCE
      OCI source label override.

Requirements:
  docker
  yq
  git

Examples:
  ${0##*/} --dry-run -f build_list.txt --pull
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --dry-run)
    dry_run="true"
    shift
    ;;
  -f | --file)
    build_list_file="${2:-}"
    shift 2
    ;;
  --file=*)
    build_list_file="${1#*=}"
    shift
    ;;
  -P | --publish)
    enable_publishing="true"
    shift
    ;;
  --pull)
    pull_images="true"
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "[ERROR] Unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
  *)
    build_list_file="$1"
    shift
    ;;
  esac
done

## Use the GitHub Actions SHA when available.
#  Fall back to the local Git revision for local execution.
short_sha="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo local)}"
short_sha="${short_sha:0:7}"

[[ -f "$build_list_file" ]] || {
  echo "[ERROR] Missing build list: $build_list_file" >&2
  exit 1
}

[[ -s "$build_list_file" ]] || {
  echo "No containers to build."
  exit 0
}

function require_metadata_value() {
  local metadata_file="$1"
  local key="$2"
  local value

  value="$(yq -r ".${key} // \"\"" "$metadata_file")"

  [[ -n "$value" ]] || {
    echo "[ERROR] Missing .${key} in $metadata_file" >&2
    exit 1
  }

  printf '%s\n' "$value"
}

echo "Processing build list: $build_list_file"
echo "Dry run:              $dry_run"
echo "Publish:              $enable_publishing"
echo "Pull base images:     $pull_images"
echo "Git tag:              $short_sha"

while IFS= read -r image_dir; do
  ## Ignore blank lines in the build list.
  [[ -n "$image_dir" ]] || continue

  metadata_file="$image_dir/metadata.yml"
  dockerfile="$image_dir/Dockerfile"

  [[ -f "$metadata_file" ]] || {
    echo "[ERROR] Missing metadata file: $metadata_file" >&2
    exit 1
  }

  [[ -f "$dockerfile" ]] || {
    echo "[ERROR] Missing Dockerfile: $dockerfile" >&2
    exit 1
  }

  ## Read static image metadata.
  image_name="$(require_metadata_value "$metadata_file" "name")"
  description="$(require_metadata_value "$metadata_file" "description")"
  registry_path="$(require_metadata_value "$metadata_file" "registry_path")"
  publish_image="$(yq -r '.publish // false' "$metadata_file")"

  ## Do not publish images marked as publish: false.
  if [[ "$publish_image" != "true" ]]; then
    echo "[INFO] Skipping unpublished image: $image_dir"
    continue
  fi

  local_tag="${image_name}:local-${short_sha}"
  latest_ref="${registry_path}:latest"
  sha_ref="${registry_path}:${short_sha}"

  ## Build arguments provide common OCI image metadata.
  #  Dependency versions are resolved from Dockerfile ARG defaults.
  build_args=(
    --build-arg "IMAGE_VERSION=${short_sha}"
    --build-arg "IMAGE_CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    --build-arg "IMAGE_SOURCE=${IMAGE_SOURCE:-https://github.com/${GITHUB_REPOSITORY:-redjax/Dockerfiles}}"
  )

  pull_args=()

  if [[ "$pull_images" == "true" ]]; then
    pull_args+=(--pull)
  fi

  ## Configure GitHub Actions cache when running in CI.
  cache_args=()

  if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
    cache_args=(
      --cache-from "type=gha,scope=${image_name}"
      --cache-to "type=gha,mode=max,scope=${image_name}"
    )
  fi

  echo
  echo "[+] Processing image: $image_name"
  echo "    Directory:         $image_dir"
  echo "    Dockerfile:        $dockerfile"
  echo "    Registry path:     $registry_path"

  if [[ "$dry_run" == "true" ]]; then
    if [[ "$enable_publishing" == "true" ]]; then
      echo "[DRY RUN] docker buildx build \\"
      echo "  --file $dockerfile \\"
      echo "  --tag $latest_ref \\"
      echo "  --tag $sha_ref \\"
      echo "  --label description=$description \\"
      printf '  %q ' "${pull_args[@]}"
      printf '%q ' "${build_args[@]}"
      printf '%q ' "${cache_args[@]}"
      echo "--push \\"
      echo "  $image_dir"
    else
      echo "[DRY RUN] docker buildx build \\"
      echo "  --file $dockerfile \\"
      echo "  --tag $local_tag \\"
      echo "  --label description=$description \\"
      printf '  %q ' "${pull_args[@]}"
      printf '%q ' "${build_args[@]}"
      printf '%q ' "${cache_args[@]}"
      echo "--load \\"
      echo "  $image_dir"
    fi

    continue
  fi

  ## Build and publish when publishing is enabled.
  if [[ "$enable_publishing" == "true" ]]; then
    echo "[INFO] Building and publishing $image_name"

    docker buildx build \
      --file "$dockerfile" \
      --tag "$latest_ref" \
      --tag "$sha_ref" \
      --label "description=${description}" \
      "${pull_args[@]}" \
      "${build_args[@]}" \
      "${cache_args[@]}" \
      --push \
      "$image_dir"

    echo "[INFO] Published:"
    echo "       $latest_ref"
    echo "       $sha_ref"

    continue
  fi

  ## Build without publishing when publishing is disabled.
  #  --load imports the image into the local Docker image store.
  #  This is useful for pull-request validation and local testing.
  echo "[INFO] Building $image_name without publishing"

  docker buildx build \
    --file "$dockerfile" \
    --tag "$local_tag" \
    --label "description=${description}" \
    "${pull_args[@]}" \
    "${build_args[@]}" \
    "${cache_args[@]}" \
    --load \
    "$image_dir"

  echo "[INFO] Publishing disabled for $image_name"
  echo "[INFO] Local image: $local_tag"

done <"$build_list_file"
