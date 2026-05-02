#!/usr/bin/env bash

#######################################################
# Generic Docker build script                         #
#                                                     #
# Builds one of the containers in this repository.    #
# Allows passing a name and tag for the image, as     #
# well as container build args and a registry prefix. #
#                                                     #
# Does not work with more complicated images.         #
#######################################################

set -euo pipefail

function usage() {
  cat <<'EOF'
Usage:
  build-image.sh --context PATH --dockerfile PATH --name NAME --tag TAG [--registry-prefix PREFIX] [--build-arg KEY=VAL ...]

Examples:
  build-image.sh --context dockerfiles/base/alpine --dockerfile dockerfiles/base/alpine/Dockerfile --name alpine-base --tag 3.22.4
  ALPINE_TAG=3.22.4 build-image.sh --context dockerfiles/base/alpine --dockerfile dockerfiles/base/alpine/Dockerfile --name alpine-base --tag "$ALPINE_TAG" --build-arg ALPINE_TAG="$ALPINE_TAG"
EOF
}

CONTEXT=""
DOCKERFILE=""
IMAGE_NAME=""
IMAGE_TAG=""
REGISTRY_PREFIX=""
BUILD_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --context)
      CONTEXT="$2"
      shift 2
      ;;
    --dockerfile)
      DOCKERFILE="$2"
      shift 2
      ;;
    --name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    --tag)
      IMAGE_TAG="$2"
      shift 2
      ;;
    --registry-prefix)
      REGISTRY_PREFIX="$2"
      shift 2
      ;;
    --build-arg)
      BUILD_ARGS+=("--build-arg" "$2")
      shift 2
      ;;
    -h|--help)
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

[[ -n "$CONTEXT" ]] || { echo "[ERROR] --context is required" >&2; exit 1; }
[[ -n "$DOCKERFILE" ]] || { echo "[ERROR] --dockerfile is required" >&2; exit 1; }
[[ -n "$IMAGE_NAME" ]] || { echo "[ERROR] --name is required" >&2; exit 1; }
[[ -n "$IMAGE_TAG" ]] || { echo "[ERROR] --tag is required" >&2; exit 1; }

FULL_IMAGE_NAME="${REGISTRY_PREFIX}${IMAGE_NAME}"

echo "Building ${FULL_IMAGE_NAME}:${IMAGE_TAG}"

docker build \
  -f "$DOCKERFILE" \
  -t "${FULL_IMAGE_NAME}:${IMAGE_TAG}" \
  "${BUILD_ARGS[@]}" \
  "$CONTEXT"

