#!/bin/bash
set -e

# This script shows the usage of an API key to create an export using the Agouti API.
# You can request one from the admins.

API_URL="http://localhost:5001"
API_KEY=`cat .apikey`
PROJECT_ID="00000000-0000-0000-0000-000000000000"

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
  -o "deployments-filtered-on-start.csv" \
  -w "Status code %{http_code}\n"

## Filter on deploymentId as comma-separated list

url="${API_URL}/project/${PROJECT_ID}/deployments.csv?deploymentId=00000000-0000-0000-0000-000000000001,00000000-0000-0000-0000-000000000002"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "deployments-filtered-on-start.csv" \
  -w "Status code %{http_code}\n"

## Filter on deploymentStart as ISO 8601 date-time

url = "${API_URL}/project/${PROJECT_ID}/deployments.csv?deploymentStart=2025-05-23T09:15:00+01:00"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "deployments-filtered-on-start.csv" \
  -w "Status code %{http_code}\n"

## Filter on locationName as comma-separated list

url="${API_URL}/project/${PROJECT_ID}/deployments.csv?locationName=WAG-01,Test1,123"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "deployments-filtered-on-location.csv" \
  -w "Status code %{http_code}\n"

# Observations

## All (this can be a lot of data)

url="${API_URL}/project/${PROJECT_ID}/observations.csv"
echo "Calling "$url

curl -sS $url
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "observations.csv" \
  -w "Status code %{http_code}\n"

## Filter on deploymentID as comma-separated list

url="${API_URL}/project/${PROJECT_ID}/observations.csv?deploymentId=00000000-0000-0000-0000-000000000001,00000000-0000-0000-0000-000000000002"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "observations-filtered-on-deployment.csv" \
  -w "Status code %{http_code}\n"

## Filter on eventStart as ISO 8601 date-time

url="${API_URL}/project/${PROJECT_ID}/observations.csv?eventStart=2025-05-23T09:15:00+01:00"
echo "Calling "$url

curl -sS $url \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "observations-filtered-on-start.csv" \
  -w "Status code %{http_code}\n"

# Media (not implemented yet)

echo "Calling "${API_URL}/project/${PROJECT_ID}/media.csv"
curl -sS "${API_URL}/project/${PROJECT_ID}/media.csv" \
  -X GET \
  -H "Accept: application/json" \
  -H "Content-Type: application/vnd.api+json" \
  -H "X-API-KEY: ${API_KEY}" \
  -o "media.csv" \
  -w "Status code %{http_code}\n"
