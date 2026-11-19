#!/usr/bin/env bash
# Create a Camtrap DP export of an Agouti project, wait until it is ready and download it.
# Replaces the deprecated create-export*.sh scripts, which used the CSV routes of the API.
#
# Usage: ./export-project.sh <projectId> [outputDir]
#
# The export is created asynchronously and takes a few minutes. The zip is unpacked into
# outputDir (default output/export-<projectId>): datapackage.json, deployments.csv,
# media.csv and observations.csv.
#
# Configuration, from the environment or the same files as the other scripts:
#   API_URL          default: the contents of .api_url, else http://localhost:5001
#   API_KEY_FILE     file with the X-API-KEY, default .api_key (e.g. .api_key_frank_prod)
#   RETENTION        how long the server keeps the zip: 1d (default), 7d, 30d or infinite
#   FILTERS          export filters as JSON, default {} (the complete project), for example
#                    '{"deploymentIds": ["<id>"]}' or '{"dateRange": {"start": "2025-05-23"}}'
#   POLL_SECONDS     seconds between status checks, default 15
#   TIMEOUT_SECONDS  give up after this many seconds, default 1800
#
# Needs curl, jq and unzip. The key's user must be admin, maintainer or coordinator of the project.
set -euo pipefail

PROJECT_ID="${1:-}"
if [[ -z "$PROJECT_ID" ]]; then
  echo "Usage: $0 <projectId> [outputDir]" >&2
  exit 2
fi
OUTPUT_DIR="${2:-output/export-$PROJECT_ID}"

for tool in curl jq unzip; do
  command -v "$tool" >/dev/null || { echo "$tool is required." >&2; exit 2; }
done

# Load configuration
if [[ -z "${API_URL:-}" ]]; then
  API_URL="http://localhost:5001"
  [[ -f ".api_url" ]] && API_URL="$(<.api_url)"
fi
API_KEY="$(<"${API_KEY_FILE:-.api_key}")"
RETENTION="${RETENTION:-1d}"
FILTERS="${FILTERS:-}"
[[ -n "$FILTERS" ]] || FILTERS='{}'
POLL_SECONDS="${POLL_SECONDS:-15}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-1800}"

BASE="$API_URL/v1/projects/$PROJECT_ID/exports"
BODY="$(jq -n --arg retention "$RETENTION" --argjson filters "$FILTERS" '{retention: $retention, filters: $filters}')"
START=$SECONDS

call() {
  curl -sS -H "X-API-KEY: $API_KEY" -H "Accept: application/json" "$@"
}

check_timeout() {
  if (( SECONDS - START >= TIMEOUT_SECONDS )); then
    echo "Gave up after $TIMEOUT_SECONDS seconds." >&2
    exit 1
  fi
}

create_export() {
  echo "Using API_URL: $API_URL" >&2
  while true; do
    local response code json
    response="$(call -X POST -H 'Content-Type: application/json' -d "$BODY" -w $'\n%{http_code}' "$BASE")"
    code="${response##*$'\n'}"
    json="${response%$'\n'*}"
    case "$code" in
      202)
        jq -r .id <<<"$json"
        return
        ;;
      409)
        echo "Another export of this project is running, waiting..." >&2
        ;;
      *)
        echo "Could not create the export (HTTP $code): $(jq -r '.message // .' <<<"$json" 2>/dev/null || echo "$json")" >&2
        exit 1
        ;;
    esac
    check_timeout
    sleep "$POLL_SECONDS"
  done
}

wait_until_completed() {
  local export_id="$1" record status
  while true; do
    record="$(call -f "$BASE/$export_id")"
    status="$(jq -r .status <<<"$record")"
    case "$status" in
      Completed)
        jq -r '"Export completed: \(.deploymentsCount) deployments, \(.mediaCount) media, \(.observationsCount) observations"' <<<"$record" >&2
        return
        ;;
      Error | Expired)
        echo "Export $status: $(jq -r '.error // empty' <<<"$record")" >&2
        exit 1
        ;;
    esac
    echo "Export $status..." >&2
    check_timeout
    sleep "$POLL_SECONDS"
  done
}

download_export() {
  local export_id="$1"
  mkdir -p "$OUTPUT_DIR"
  call -f -o "$OUTPUT_DIR/export.zip" "$BASE/$export_id/archive"
  unzip -o -q "$OUTPUT_DIR/export.zip" -d "$OUTPUT_DIR"
  echo "Downloaded to $OUTPUT_DIR" >&2
}

# Main execution
EXPORT_ID="$(create_export)"
echo "Created export $EXPORT_ID (kept for $RETENTION after it completes)" >&2
wait_until_completed "$EXPORT_ID"
download_export "$EXPORT_ID"
