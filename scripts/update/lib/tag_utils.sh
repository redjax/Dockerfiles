#!/usr/bin/env bash

function latest_tag_for_track() {
  local track="$1"
  local tag

  while IFS= read -r tag; do
    [[ -z "$tag" ]] && continue

    case "$track" in
      *-slim)
        if [[ "$tag" == "$track" || "$tag" == "${track}"-* || "$tag" == "${track%}-"*"-slim" ]]; then
          printf '%s\n' "$tag"
        fi
        ;;
      [0-9]*)
        if [[ "$tag" == "$track" || "$tag" == "$track".* ]]; then
          if [[ "$tag" != *-slim ]]; then
            printf '%s\n' "$tag"
          fi
        fi
        ;;
      *)
        if [[ "$tag" == "$track" || "$tag" == "$track"-* ]]; then
          if [[ "$tag" != *-slim || "$track" == *-slim ]]; then
            printf '%s\n' "$tag"
          fi
        fi
        ;;
    esac
  done | sort -V | tail -n1
}
