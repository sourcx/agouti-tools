#!/bin/bash

# This script shows the usage of an API key for the Agouti API.
# You can request one from the admins.

API_URL="http://localhost:5001"
API_KEY=`cat .apikey`

if [[ -z "${API_URL}" ]]; then
  echo "API_URL must be set."
  exit 1
fi

if [[ -z "${API_KEY}" ]]; then
  echo "API_KEY must be set."
  exit 1
fi

response=$( \
  curl -sS "${API_URL}/ages" \
    -X GET \
    -H "Accept: application/json" \
    -H "Content-Type: application/vnd.api+json" \
    -H "X-API-KEY: ${API_KEY}" \
)

echo "${response}" | json_pp
