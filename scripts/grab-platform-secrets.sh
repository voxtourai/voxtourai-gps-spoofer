#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MANIFEST_FILE="${ROOT_DIR}/scripts/platform-secrets.manifest"

if [[ ! -f "${MANIFEST_FILE}" ]]; then
  echo "Missing manifest ${MANIFEST_FILE}" >&2
  exit 1
fi

resolve_secret() {
  local env_name="$1"
  local secret_name="$2"
  local env_value="${!env_name:-}"
  local gcloud_project="${GOOGLE_CLOUD_PROJECT:-${GCLOUD_PROJECT:-}}"
  local -a gcloud_args=()

  if [[ -n "${env_value}" ]]; then
    printf '%s' "${env_value}"
    return
  fi

  if command -v gcloud >/dev/null 2>&1; then
    if [[ -n "${gcloud_project}" ]]; then
      gcloud_args+=(--project="${gcloud_project}")
    fi
    gcloud secrets versions access latest --secret="${secret_name}" "${gcloud_args[@]}"
    return
  fi

  echo "Unable to resolve ${env_name}. Set ${env_name} or install gcloud to access secret ${secret_name}." >&2
  exit 1
}

file_path_formats=""

get_recorded_format() {
  local relative_path="$1"
  local recorded_path
  local recorded_format

  while IFS='|' read -r recorded_path recorded_format; do
    [[ -z "${recorded_path}" ]] && continue

    if [[ "${recorded_path}" == "${relative_path}" ]]; then
      printf '%s' "${recorded_format}"
      return 0
    fi
  done <<< "${file_path_formats}"

  return 1
}

while IFS='|' read -r relative_path format output_key env_name secret_name; do
  [[ -z "${relative_path}" || "${relative_path}" == \#* ]] && continue

  if existing_format="$(get_recorded_format "${relative_path}")"; then
    if [[ "${existing_format}" != "${format}" ]]; then
      echo "Conflicting formats for ${relative_path}: ${existing_format} and ${format}" >&2
      exit 1
    fi
  else
    file_path_formats+="${relative_path}|${format}"$'\n'

    absolute_path="${ROOT_DIR}/${relative_path}"
    mkdir -p "$(dirname "${absolute_path}")"

    case "${format}" in
      properties)
        : > "${absolute_path}"
        ;;
      *)
        echo "Unsupported format ${format} in ${MANIFEST_FILE}" >&2
        exit 1
        ;;
    esac
  fi

  value="$(resolve_secret "${env_name}" "${secret_name}")"
  absolute_path="${ROOT_DIR}/${relative_path}"

  case "${format}" in
    properties)
      printf '%s=%s\n' "${output_key}" "${value}" >> "${absolute_path}"
      ;;
    *)
      echo "Unsupported format ${format} in ${MANIFEST_FILE}" >&2
      exit 1
      ;;
  esac
done < "${MANIFEST_FILE}"
