#!/usr/bin/env bash

function latest_tag_for_track() {
  local track="$1"
  local tag
  local plain_tags=()
  local suffix_tags=()

  while IFS= read -r tag; do
    [[ -z "$tag" ]] && continue

    case "$track" in
      *-slim)
        if [[ "$tag" == "$track" || "$tag" == "$track"-* ]]; then
          plain_tags+=("$tag")
        fi
        ;;
      v[0-9]*.[0-9]*)
        if [[ "$tag" == "$track" || "$tag" == "$track".[0-9]* ]]; then
          if [[ "$tag" == "$track" || "$tag" == "$track".[0-9]* && "$tag" != *-* ]]; then
            plain_tags+=("$tag")
          else
            suffix_tags+=("$tag")
          fi
        fi
        ;;
      [0-9]*)
        if [[ "$tag" == "$track" || "$tag" == "$track".[0-9]* ]]; then
          if [[ "$tag" == "$track" || "$tag" == "$track".[0-9]* && "$tag" != *-* ]]; then
            plain_tags+=("$tag")
          else
            suffix_tags+=("$tag")
          fi
        fi
        ;;
      *)
        if [[ "$tag" == "$track" || "$tag" == "$track"-* ]]; then
          if [[ "$track" == *-* || "$tag" != *-* ]]; then
            plain_tags+=("$tag")
          else
            suffix_tags+=("$tag")
          fi
        fi
        ;;
    esac
  done

  if ((${#plain_tags[@]} > 0)); then
    printf '%s\n' "${plain_tags[@]}" | sort -V | tail -n1
  else
    printf '%s\n' "${suffix_tags[@]}" | sort -t. -k1,1V -k2,2V -k3,3V | tail -n1
  fi
}
