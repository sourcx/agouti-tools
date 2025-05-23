#!/bin/bash

# This script shows the usage of an API key to create an export using the Agouti API.
# You can request one from the admins.

API_URL="http://localhost:5001"
API_KEY=`cat .apikey`
PROJECT_ID="8b0896be-2dd7-4229-8350-961cb430d6d5"

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

curl -sS "${API_URL}/project/${PROJECT_ID}/deployments.csv" \
-X GET \
-H "Accept: application/json" \
-H "Content-Type: application/vnd.api+json" \
-H "X-API-KEY: ${API_KEY}" \
-o "deployments.csv" \
-w "%{http_code}"

curl -sS "${API_URL}/project/${PROJECT_ID}/observations.csv" \
-X GET \
-H "Accept: application/json" \
-H "Content-Type: application/vnd.api+json" \
-H "X-API-KEY: ${API_KEY}" \
-o "observations.csv" \
-w "%{http_code}"

curl -sS "${API_URL}/project/${PROJECT_ID}/media.csv" \
-X GET \
-H "Accept: application/json" \
-H "Content-Type: application/vnd.api+json" \
-H "X-API-KEY: ${API_KEY}" \
-o "media.csv" \
-w "%{http_code}"
