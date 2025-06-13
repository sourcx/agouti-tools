#!/usr/bin/env bash
set -euo pipefail

# Load configuration
API_URL="http://localhost:5001"
[[ -f ".api_url" ]] && API_URL="$(<.api_url)"
API_KEY="$(<.api_key)"
PROJECT_ID="0922a347-264f-4e8e-bb4a-f6b74229f07f"

# Ensure required vars
for var in API_URL API_KEY PROJECT_ID; do
  if [[ -z "${!var}" ]]; then
    echo "$var must be set." >&2
    exit 1
  fi
done

# Create output directory
mkdir -p output

echo "Using API_URL: $API_URL"

echo "# Fetch all deployments"
fetch_all_deployments() {
  local url="$API_URL/project/$PROJECT_ID/deployments.csv"
  echo "Calling $url"
  curl -sS "$url" \
    -H "Accept: application/json" \
    -H "Content-Type: application/vnd.api+json" \
    -H "X-API-KEY: $API_KEY" \
    -o "output/deployments.csv" \
    -w "Status code %{http_code}\n"
}

fetch_deployments_by_id() {
  local url="$API_URL/project/$PROJECT_ID/deployments.csv?deploymentID=e43ceedb-2a8e-45d1-a7e6-8577dd5444f9,f5918597-20a7-4743-ac9c-3a255d8ddb49"
  echo "Calling $url"
  curl -sS "$url" \
    -H "Accept: application/json" \
    -H "Content-Type: application/vnd.api+json" \
    -H "X-API-KEY: $API_KEY" \
    -o "output/deployments-filtered-on-id.csv" \
    -w "Status code %{http_code}\n"
}

fetch_deployments_by_start() {
  local url="$API_URL/project/$PROJECT_ID/deployments.csv?deploymentStart=2025-05-23T09:15:00+01:00"
  echo "Calling $url"
  curl -sS "$url" \
    -H "Accept: application/json" \
    -H "Content-Type: application/vnd.api+json" \
    -H "X-API-KEY: $API_KEY" \
    -o "output/deployments-filtered-on-start.csv" \
    -w "Status code %{http_code}\n"
}

fetch_deployments_by_location() {
  local url="$API_URL/project/$PROJECT_ID/deployments.csv?locationName=WAG-01,Test1,123"
  echo "Calling $url"
  curl -sS "$url" \
    -H "Accept: application/json" \
    -H "Content-Type: application/vnd.api+json" \
    -H "X-API-KEY: $API_KEY" \
    -o "output/deployments-filtered-on-location.csv" \
    -w "Status code %{http_code}\n"
}

fetch_all_observations() {
  local url="$API_URL/project/$PROJECT_ID/observations.csv"
  echo "Calling $url"
  curl -sS "$url" \
    -H "Accept: application/json" \
    -H "Content-Type: application/vnd.api+json" \
    -H "X-API-KEY: $API_KEY" \
    -o "output/observations.csv" \
    -w "Status code %{http_code}\n"
}

fetch_observations_by_deployment() {
  local url="$API_URL/project/$PROJECT_ID/observations.csv?deploymentID=05799f29-fa71-4f68-ae57-f74e6e71e397,a326e571-5e51-4f53-a01f-ab33027a7241"
  echo "Calling $url"
  curl -sS "$url" \
    -H "Accept: application/json" \
    -H "Content-Type: application/vnd.api+json" \
    -H "X-API-KEY: $API_KEY" \
    -o "output/observations-filtered-on-deployment.csv" \
    -w "Status code %{http_code}\n"
}

fetch_observations_by_start() {
  local url="$API_URL/project/$PROJECT_ID/observations.csv?eventStart=2022-01-01T12:00:00.000Z"
  echo "Calling $url"
  curl -sS "$url" \
    -H "Accept: application/json" \
    -H "Content-Type: application/vnd.api+json" \
    -H "X-API-KEY: $API_KEY" \
    -o "output/observations-filtered-on-start.csv" \
    -w "Status code %{http_code}\n"
}

fetch_observations_by_deployment_and_start() {
  local url="$API_URL/project/$PROJECT_ID/observations.csv?deploymentID=a326e571-5e51-4f53-a01f-ab33027a7241&eventStart=2022-01-01T12:00:00.000Z"
  echo "Calling $url"
  curl -sS "$url" \
    -H "Accept: application/json" \
    -H "Content-Type: application/vnd.api+json" \
    -H "X-API-KEY: $API_KEY" \
    -o "output/observations-filtered-on-deployment-and-start.csv" \
    -w "Status code %{http_code}\n"
}

# Main execution
fetch_all_deployments
fetch_deployments_by_id
fetch_deployments_by_start
fetch_deployments_by_location

fetch_all_observations
fetch_observations_by_deployment
fetch_observations_by_start
fetch_observations_by_deployment_and_start
