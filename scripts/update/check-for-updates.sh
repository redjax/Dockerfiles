#!/usr/bin/env bash
set -euo pipefail

#############################################################
# Scan all image manifests in the repo for available        #
# upstream updates without modifying any files.             #
#                                                           #
# Use this script to check for new trackable versions/tags. #
#############################################################

for cmd in curl yq jq awk sort head tail grep cut tr; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[ERROR] $cmd is not installed" >&2; exit 1; }
done

THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${THIS_DIR}/lib"

source "${LIB_DIR}/components.sh"
source "${LIB_DIR}/tag_utils.sh"
source "${LIB_DIR}/dockerhub.sh"
source "${LIB_DIR}/ghcr.sh"
source "${LIB_DIR}/gitlab.sh"
source "${LIB_DIR}/acr.sh"
source "${LIB_DIR}/gh-release.sh"

function usage() {
  cat <<EOF
Usage:
  $0 [OPTIONS]

Options:
  --summary    Print shorter output
  --path PATH  Limit scan to a subdirectory
  -h, --help   Show this help menu
EOF
}

SUMMARY=false
SCAN_PATH="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --summary)
      SUMMARY=true
      shift
      ;;
    --path)
      SCAN_PATH="$2"
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

[[ -d "$SCAN_PATH" ]] || { echo "[ERROR] Scan path not found: $SCAN_PATH" >&2; exit 1; }

function get_tags() {
  local registry="$1"
  local name="$2"

  case "$registry" in
    docker)
      dockerhub_list_tags "$name"
      ;;
    ghcr)
      ghcr_list_tags "$name"
      ;;
    gitlab)
      gitlab_list_tags "$name"
      ;;
    acr)
      acr_list_tags "$name"
      ;;
    github_release)
      github_list_tags "$name"
      ;;
    *) return 1 ;;
  esac
}

function get_latest_version() {
  local registry="$1"
  local name="$2"
  local track="$3"

  case "$registry" in
    docker)
      dockerhub_latest_version_tag "$name" "$track"
      ;;
    ghcr)
      ghcr_latest_version_tag "$name" "$track"
      ;;
    gitlab)
      gitlab_latest_version_tag "$name" "$track"
      ;;
    acr)
      acr_latest_version_tag "$name" "$track"
      ;;
    github_release)
      github_list_tags "$name" | latest_tag_for_track "$track"
      ;;
    manual)
      echo ""
      ;;
    *)
      echo "[ERROR] Unsupported registry: $registry" >&2; return 1
      ;;
  esac
}

function version_key() {
  local tag="$1"
  local major minor patch prefix

  prefix=""
  [[ "$tag" == v* ]] && prefix="v" && tag="${tag#v}"

  major="$(printf '%s' "$tag" | cut -d. -f1)"
  minor="$(printf '%s' "$tag" | cut -d. -f2)"
  patch="$(printf '%s' "$tag" | cut -d. -f3)"

  [[ -z "$minor" ]] && minor=0
  [[ -z "$patch" ]] && patch=0

  printf '%s%09d.%09d.%09d\n' "$prefix" "$major" "$minor" "$patch"
}

function sort_versions() {
  while IFS= read -r line; do
    [[ -n "$line" ]] && printf '%s\t%s\n' "$(version_key "$line")" "$line"
  done | sort -k1,1 | awk -F'\t' '{print $2}'
}

function highest_track_for_tags() {
  local track="$1"
  shift
  local tags=("$@")
  local prefix current_major current_minor best=""

  [[ "$track" == v* ]] && prefix="v" || prefix=""
  track="${track#v}"

  current_major="$(printf '%s' "$track" | cut -d. -f1)"
  current_minor="$(printf '%s' "$track" | cut -s -d. -f2)"

  for tag in "${tags[@]}"; do
    t="$tag"
    [[ "$t" == v* ]] && t="${t#v}"

    major="$(printf '%s' "$t" | cut -d. -f1)"
    minor="$(printf '%s' "$t" | cut -s -d. -f2)"

    [[ -z "$major" ]] && continue
    [[ -z "$minor" ]] && continue

    if [[ "$major" =~ ^[0-9]+$ && "$minor" =~ ^[0-9]+$ ]]; then
      if [[ -z "$current_minor" ]]; then
        if (( major > current_major )); then
          candidate="${tag}"
          if [[ -z "$best" || "$(version_key "$candidate")" > "$(version_key "$best")" ]]; then
            best="$candidate"
          fi
        fi
      else
        if (( major > current_major )) || { (( major == current_major )) && (( minor > current_minor )); }; then
          candidate="${tag%.*}"
          if [[ -z "$best" || "$(version_key "$candidate")" > "$(version_key "$best")" ]]; then
            best="$candidate"
          fi
        fi
      fi
    fi
  done

  printf '%s\n' "$best"
}

function current_track_label() {
  local track="$1"

  if [[ "$track" == *.* ]]; then
    printf '%s\n' "${track%.*}"
  else
    printf '%s\n' "$track"
  fi
}

mapfile -t manifests < <(find "$SCAN_PATH" -name image.yml -type f | sort)

if ((${#manifests[@]} == 0)); then
  echo "No image manifests found."
  exit 0
fi

found_updates=false

for file in "${manifests[@]}"; do
  publish="$(yq e '.publish // false' "$file")"
  [[ "$publish" == "true" ]] || continue

  name="$(yq e '.name' "$file")"
  registry="$(yq e '.upstream.registry' "$file")"
  upstream_name="$(yq e '.upstream.name' "$file")"
  track="$(yq e '.upstream.track' "$file")"
  current="$(yq e '.upstream.version' "$file")"

  [[ -n "$registry" && "$registry" != "null" ]] || continue
  [[ -n "$upstream_name" && "$upstream_name" != "null" ]] || continue
  [[ -n "$track" && "$track" != "null" ]] || continue
  [[ -n "$current" && "$current" != "null" ]] || continue

  mapfile -t tags < <(get_tags "$registry" "$upstream_name" 2>/dev/null || true)
  [[ ${#tags[@]} -gt 0 ]] || continue

  latest_in_track="$(printf '%s\n' "${tags[@]}" | latest_tag_for_track "$track" || true)"
  next_track="$(highest_track_for_tags "$track" "${tags[@]}")"
  current_track_label="$(current_track_label "$track")"

  needs_update=false
  reasons=()

  if [[ -n "$latest_in_track" && "$latest_in_track" != "$current" ]]; then
    needs_update=true
    reasons+=("current track update: $current -> $latest_in_track")
  fi

  if [[ -n "$next_track" && "$next_track" != "$track" && "$next_track" != "$current_track_label" ]]; then
    needs_update=true
    reasons+=("new track available: $track -> $next_track")
  fi

  while IFS= read -r key; do
    [[ -n "$key" ]] || continue

    version_val="$(yq e ".version_args.${key}" "$file")"
    args_val="$(yq e ".args.${key}" "$file")"

    if [[ "$version_val" != "$args_val" ]]; then
      needs_update=true
      reasons+=("version arg drift: ${key}=${args_val} -> ${version_val}")
    fi
  done < <(yq e '.version_args | keys | .[]' "$file" 2>/dev/null || true)

  while IFS= read -r component; do
    [[ -n "$component" ]] || continue

    type="$(yq e ".components.${component}.type" "$file")"
    comp_track="$(yq e ".components.${component}.track" "$file")"
    comp_current="$(yq e ".components.${component}.version" "$file")"

    [[ -n "$type" && "$type" != "null" ]] || continue

    identifier=""
    case "$type" in
      dockerhub) identifier="$(yq e ".components.${component}.name" "$file")" ;;
      github_release) identifier="$(yq e ".components.${component}.repo" "$file")" ;;
      ghcr|gitlab|acr) identifier="$(yq e ".components.${component}.name" "$file")" ;;
      *) continue ;;
    esac

    mapfile -t comp_tags < <(get_tags "$type" "$identifier" 2>/dev/null || true)
    [[ ${#comp_tags[@]} -gt 0 ]] || continue

    latest_comp="$(printf '%s\n' "${comp_tags[@]}" | latest_tag_for_track "$comp_track" || true)"
    next_comp_track="$(highest_track_for_tags "$comp_track" "${comp_tags[@]}")"
    comp_track_label="$(current_track_label "$comp_track")"

    if [[ -n "$latest_comp" && "$latest_comp" != "$comp_current" ]]; then
      needs_update=true
      reasons+=("component ${component} update: ${comp_current} -> ${latest_comp}")
    fi

    if [[ -n "$next_comp_track" && "$next_comp_track" != "$comp_track" && "$next_comp_track" != "$comp_track_label" ]]; then
      needs_update=true
      reasons+=("component ${component} new track: ${comp_track} -> ${next_comp_track}")
    fi
  done < <(yq e '.components | keys | .[]' "$file" 2>/dev/null || true)

  if [[ "$needs_update" == true ]]; then
    found_updates=true
    if [[ "$SUMMARY" == true ]]; then
      echo "${name}: update available"
      printf '  - %s\n' "${reasons[@]}"
    else
      echo "Update available for ${name} (${file})"
      printf '  - %s\n' "${reasons[@]}"
    fi
  elif [[ "$SUMMARY" == false ]]; then
    echo "Up to date: ${name} (${file})"
  fi
done

if [[ "$found_updates" == false ]]; then
  echo "No updates found."
fi
