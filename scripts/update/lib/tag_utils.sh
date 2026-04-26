#!/usr/bin/env bash

function latest_tag_for_track() {
  local track="$1"
  local tag
  local matched_tags=()

  while IFS= read -r tag; do
    [[ -z "$tag" ]] && continue

    case "$track" in
      *-slim)
        if [[ "$tag" == "$track" || "$tag" == "${track}"-* || "$tag" == "${track%}-"*"-slim" ]]; then
          matched_tags+=("$tag")
        fi
        ;;
      v[0-9]*.[0-9]*)
        if [[ "$tag" == "$track" || "$tag" == "$track".* ]]; then
          matched_tags+=("$tag")
        fi
        ;;
      [0-9]*)
        if [[ "$tag" == "$track" || "$tag" == "$track".* ]]; then
          if [[ "$tag" != *-* ]]; then
            matched_tags+=("$tag")
          fi
        fi
        ;;
      *)
        if [[ "$tag" == "$track" || "$tag" == "$track"-* ]]; then
          if [[ "$track" == *-* || "$tag" != *-* ]]; then
            matched_tags+=("$tag")
          fi
        fi
        ;;
    esac
  done

  printf '%s\n' "${matched_tags[@]}" | sort -V | tail -n1
}
