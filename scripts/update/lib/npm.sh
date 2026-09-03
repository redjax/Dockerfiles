#!/usr/bin/env bash

function npm_latest_version_tag() {
  local name="$1"
  local track="${2:-}"

  local metadata
  metadata="$(
    curl --fail --silent --show-error --location \
      "https://registry.npmjs.org/${name}"
  )"

  local candidates=""

  if [[ -z "$track" || "$track" == "null" ]]; then
    candidates="$(
      jq -r '
        .versions
        | keys[]
        | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
      ' <<<"$metadata"
    ) || return 1
  else
    candidates="$(
      jq -r --arg track "$track" '
        .versions
        | keys[]
        | select(
            test(
              "^" +
              ($track | gsub("\\."; "\\\\.")) +
              "\\.[0-9]+\\.[0-9]+$"
            )
          )
      ' <<<"$metadata"
    ) || return 1
  fi

  if [[ -z "$candidates" ]]; then
    return 0
  fi

  sort -V <<<"$candidates" | tail -n1
}
