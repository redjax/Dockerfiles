#!/usr/bin/env bash

function npm_latest_version_tag() {
  local name="$1"
  local track="${2:-}"

  local metadata
  metadata="$(
    curl --fail --silent --show-error --location \
      "https://registry.npmjs.org/${name}"
  )"

  if [[ -z "$track" || "$track" == "null" ]]; then
    jq -r '
      .versions
      | keys[]
      | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))
    ' <<<"$metadata" |
      sort -V |
      tail -n1
    return 0
  fi

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
  ' <<<"$metadata" |
    sort -V |
    tail -n1
}
