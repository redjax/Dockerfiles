#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/dockerhub.sh"
source "$(dirname "${BASH_SOURCE[0]}")/ghcr.sh"
source "$(dirname "${BASH_SOURCE[0]}")/gitlab.sh"
source "$(dirname "${BASH_SOURCE[0]}")/acr.sh"
source "$(dirname "${BASH_SOURCE[0]}")/gh-release.sh"
source "$(dirname "${BASH_SOURCE[0]}")/tag_utils.sh"

function resolve_component_version() {
  local type="$1"
  local identifier="$2"
  local track="$3"

  case "$type" in
    dockerhub)
      dockerhub_latest_version_tag "$identifier" "$track"
      ;;
    github_release)
      github_list_tags "$identifier" | latest_tag_for_track "$track"
      ;;
    ghcr)
      ghcr_latest_version_tag "$identifier" "$track"
      ;;
    gitlab)
      gitlab_latest_version_tag "$identifier" "$track"
      ;;
    acr)
      acr_latest_version_tag "$identifier" "$track"
      ;;
    *)
      echo "[ERROR] Unknown component type: $type" >&2
      return 1
      ;;
  esac
}
