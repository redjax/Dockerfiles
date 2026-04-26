#!/usr/bin/env bash

function latest_tag_for_track() {
  local track="$1"

  awk -v track="$track" '
    $0 == track || index($0, track ".") == 1 { print }
  ' | sort -V | tail -n1
}
