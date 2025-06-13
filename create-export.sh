#!/bin/bash
set -e

# This script shows the usage of an API key to create an export using the Agouti API.
# You can request one from the admins.

API_URL="http://localhost:5001"

if [[ -f ".api_url" ]]; then
  API_URL="$(<.api_url)"
fi

API_KEY=`cat .api_key`
PROJECT_ID="0922a347-264f-4e8e-bb4a-f6b74229f07f"

if [[ -z "${API_URL}" ]]; then
  echo "API_URL must be set."
  exit 1
fi

if [[ -z "${PROJECT_ID}" ]]; then
  echo "PROJECT_ID must be set."
  exit 1
fi

if [[ -z "${API_KEY}" ]]; then
  echo "API_KEY must be set."
  exit 1
fi

# Deployments

## All (this can be a lot of data)

url="${API_URL}/project/${PROJECT_ID}/deployments.csv"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "output/deployments.csv" \
  -w "Status code %{http_code}\n"

# ## Filter on deploymentID as comma-separated list

url="${API_URL}/project/${PROJECT_ID}/deployments.csv?deploymentID=e43ceedb-2a8e-45d1-a7e6-8577dd5444f9,f5918597-20a7-4743-ac9c-3a255d8ddb49"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "output/deployments-filtered-on-id.csv" \
  -w "Status code %{http_code}\n"

# ## Filter on deploymentStart as ISO 8601 date-time

url="${API_URL}/project/${PROJECT_ID}/deployments.csv?deploymentStart=2025-05-23T09:15:00+01:00"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "output/deployments-filtered-on-start.csv" \
  -w "Status code %{http_code}\n"

# ## Filter on locationName as comma-separated list

url="${API_URL}/project/${PROJECT_ID}/deployments.csv?locationName=WAG-01,Test1,123"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "output/deployments-filtered-on-location.csv" \
  -w "Status code %{http_code}\n"

# # Observations

# ## All (this can be a lot of data)

url="${API_URL}/project/${PROJECT_ID}/observations.csv"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "output/observations.csv" \
  -w "Status code %{http_code}\n"

# ## Filter on deploymentID as comma-separated list

url="${API_URL}/project/${PROJECT_ID}/observations.csv?deploymentID=05799f29-fa71-4f68-ae57-f74e6e71e397,a326e571-5e51-4f53-a01f-ab33027a7241"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "output/observations-filtered-on-deployment.csv" \
  -w "Status code %{http_code}\n"

## Filter on eventStart as ISO 8601 date-time

url="${API_URL}/project/${PROJECT_ID}/observations.csv?eventStart=2022-01-01T12:00:00.000Z"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "output/observations-filtered-on-start.csv" \
  -w "Status code %{http_code}\n"

## Filter on deploymentID and eventStart

url="${API_URL}/project/${PROJECT_ID}/observations.csv?deploymentID=a326e571-5e51-4f53-a01f-ab33027a7241&eventStart=2022-01-01T12:00:00.000Z"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "output/observations-filtered-on-deployment-and-start.csv" \
  -w "Status code %{http_code}\n"

# Media (not implemented yet)

# echo "Calling "${API_URL}/project/${PROJECT_ID}/media.csv"
# curl -sS "${API_URL}/project/${PROJECT_ID}/media.csv" \
#   -X GET \
#   -H "Accept: application/json" \
#   -H "Content-Type: application/vnd.api+json" \
#   -H "X-API-KEY: ${API_KEY}" \
#   -o "output/media.csv" \
#   -w "Status code %{http_code}\n"
