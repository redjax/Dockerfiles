#!/usr/bin/env bash
set -euo pipefail

KICS_VERSION="${KICS_VERSION:-2.1.20}"
KICS_REPO="https://github.com/Checkmarx/kics/releases/download"

os="linux"
arch="$(uname -m)"

case "${arch}" in
x86_64)
  arch="amd64"
  ;;
aarch64 | arm64)
  arch="arm64"
  ;;
*)
  echo "Unsupported architecture: ${arch}" >&2
  exit 1
  ;;
esac

asset="kics_${KICS_VERSION}_${os}_${arch}.tar.gz"
assets_zip="extracted-info.zip"
release_url="${KICS_REPO}/v${KICS_VERSION}"

workdir="$(mktemp -d)"
trap 'rm -rf "${workdir}"' EXIT

curl -fsSL "${release_url}/${asset}" -o "${workdir}/${asset}"
curl -fsSL "${release_url}/${assets_zip}" -o "${workdir}/${assets_zip}"
curl -fsSL "${release_url}/checksums.txt" -o "${workdir}/checksums.txt"

expected_line="$(grep " ${asset}$" "${workdir}/checksums.txt" || true)"
if [[ -z "${expected_line}" ]]; then
  echo "Checksum entry not found for ${asset}" >&2
  exit 1
fi

expected_assets_line="$(grep " ${assets_zip}$" "${workdir}/checksums.txt" || true)"

expected_assets_sha=""
if [[ -z "${expected_assets_line}" ]]; then
  echo "Checksum entry not found for ${assets_zip}; attempting GitHub API digest fallback." >&2
  release_meta_url="https://api.github.com/repos/Checkmarx/kics/releases/tags/v${KICS_VERSION}"
  curl_args=(
    -fsSL
    -H 'Accept: application/vnd.github+json'
    -H 'User-Agent: kics-installer'
  )

  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi

  release_meta="$(curl "${curl_args[@]}" "${release_meta_url}" || true)"

  if [[ -n "${release_meta}" ]]; then
    release_meta_min="$(printf '%s' "${release_meta}" | tr -d '\n\r')"
    expected_assets_sha="$(printf '%s' "${release_meta_min}" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"'"${assets_zip}"'"[^}]*"digest"[[:space:]]*:[[:space:]]*"sha256:\([0-9a-fA-F]\{64\}\)".*/\1/p')"
  fi

  if [[ -z "${expected_assets_sha}" ]]; then
    echo "Warning: unable to resolve GitHub API digest for ${assets_zip}; continuing without zip checksum verification." >&2
  fi
fi

printf '%s\n' "${expected_line}" >"${workdir}/asset.sha256"
(
  cd "${workdir}"
  sha256sum -c "asset.sha256"
  if [[ -n "${expected_assets_line}" ]]; then
    printf '%s\n' "${expected_assets_line}" >"assets.sha256"
    sha256sum -c "assets.sha256"
  elif [[ -n "${expected_assets_sha}" ]]; then
    printf '%s  %s\n' "${expected_assets_sha}" "${assets_zip}" >"assets.sha256"
    sha256sum -c "assets.sha256"
  fi
)

tar -xzf "${workdir}/${asset}" -C "${workdir}"
unzip -q "${workdir}/${assets_zip}" -d "${workdir}/extracted-info"

kics_bin="$(find "${workdir}" -type f -name kics -perm -u+x | head -n 1 || true)"

if [[ -z "${kics_bin}" ]]; then
  echo "KICS binary not found after extracting ${asset}" >&2
  exit 1
fi

queries_dir="$(find "${workdir}/extracted-info" -type d -path '*/assets/queries' | head -n 1 || true)"

if [[ -z "${queries_dir}" ]]; then
  queries_dir="$(find "${workdir}/extracted-info" -type d -name queries | head -n 1 || true)"
fi

if [[ -z "${queries_dir}" ]]; then
  echo "KICS assets/queries directory not found after extracting ${assets_zip}" >&2
  exit 1
fi

if [[ "$(basename "${queries_dir}")" == "queries" && "$(basename "$(dirname "${queries_dir}")")" != "assets" ]]; then
  assets_dir="$(dirname "${queries_dir}")"

  mkdir -p "${workdir}/normalized-assets/assets"
  cp -a "${queries_dir}" "${workdir}/normalized-assets/assets/queries"

  assets_dir="${workdir}/normalized-assets/assets"
else

  assets_dir="$(dirname "${queries_dir}")"
fi

install -m 0755 "${kics_bin}" /usr/local/bin/kics

mkdir -p /assets
cp -a "${assets_dir}"/. /assets/

kics version
