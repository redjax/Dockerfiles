#!/usr/bin/env bash

############################################################
# Generic Docker image build script.                       #
#                                                          #
# Builds one image directory containing:                   #
#                                                          #
#   <image-directory>/Dockerfile                           #
#   <image-directory>/metadata.yml                         #
#                                                          #
# The image directory is used as the Docker build context. #
# Dockerfile ARG defaults provide dependency versions.     #
#                                                          #
# This script does not read or modify dependency versions. #
# Renovate updates those values directly in the Dockerfile.#
############################################################

set -euo pipefail

IMAGE_DIR=""
IMAGE_TAG=""
PULL_IMAGES="false"

function usage() {
  cat <<'EOF'
Usage:
  build-image.sh \
    --image-dir PATH \
    [--tag TAG] \
    [--pull]


Description:
  Builds one Docker image from an image directory.


Arguments:
  --image-dir PATH    Directory containing Dockerfile and metadata.yml.
  --tag TAG           Local image tag. Default: dev.
  --pull              Always pull base images before building.
  -h, --help          Show this help message.


Example:
  build-image.sh \
    --image-dir dockerfiles/base/alpine \
    --tag local \
    --pull
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --image-dir)
    IMAGE_DIR="${2:-}"
    shift 2
    ;;
  --image-dir=*)
    IMAGE_DIR="${1#*=}"
    shift
    ;;
  --tag)
    IMAGE_TAG="${2:-}"
    shift 2
    ;;
  --tag=*)
    IMAGE_TAG="${1#*=}"
    shift
    ;;
  --pull)
    PULL_IMAGES="true"
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

IMAGE_TAG="${IMAGE_TAG:-dev}"

[[ -n "$IMAGE_DIR" ]] || {
  echo "[ERROR] --image-dir is required" >&2
  exit 1
}

[[ -f "$IMAGE_DIR/Dockerfile" ]] || {
  echo "[ERROR] Missing Dockerfile: $IMAGE_DIR/Dockerfile" >&2
  exit 1
}

[[ -f "$IMAGE_DIR/metadata.yml" ]] || {
  echo "[ERROR] Missing metadata.yml: $IMAGE_DIR/metadata.yml" >&2
  exit 1
}

## Read static metadata for the local image name and description.
#  Dependency versions are intentionally not read from metadata.yml.
IMAGE_NAME="$(yq -r '.name // ""' "$IMAGE_DIR/metadata.yml")"
DESCRIPTION="$(yq -r '.description // ""' "$IMAGE_DIR/metadata.yml")"

[[ -n "$IMAGE_NAME" ]] || {
  echo "[ERROR] Missing .name in $IMAGE_DIR/metadata.yml" >&2
  exit 1
}

## Build arguments used by the Dockerfiles for OCI metadata.
#  Renovated dependency ARG values remain in the Dockerfile itself.
BUILD_ARGS=(
  --build-arg "IMAGE_VERSION=${IMAGE_VERSION:-$IMAGE_TAG}"
  --build-arg "IMAGE_CREATED=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  --build-arg "IMAGE_SOURCE=${IMAGE_SOURCE:-https://github.com/${GITHUB_REPOSITORY:-redjax/Dockerfiles}}"
)

## Add --pull when requested.
if [[ "$PULL_IMAGES" == "true" ]]; then
  BUILD_ARGS+=(--pull)
fi

echo
echo "[INFO] Building image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "[INFO] Build context:  ${IMAGE_DIR}"
echo "[INFO] Dockerfile:     ${IMAGE_DIR}/Dockerfile"

docker build \
  --file "$IMAGE_DIR/Dockerfile" \
  --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
  --label "description=${DESCRIPTION}" \
  "${BUILD_ARGS[@]}" \
  "$IMAGE_DIR"
