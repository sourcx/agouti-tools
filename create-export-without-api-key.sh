```sh

# This script shows how to create an export without using an API key.

# Create an export for a project using the website.
# Enter your project id here and get the token from the inspector in the webbrowser.

API_URL="http://localhost:5001"
PROJECT_ID=""
TOKEN=""

if [[ -z "${API_URL}" ]]; then
  echo "API_URL must be set."
  exit 1
fi

if [[ -z "${PROJECT_ID}" ]]; then
  echo "PROJECT_ID must be set."
  exit 1
fi

if [[ -z "${TOKEN}" ]]; then
  echo "TOKEN must be set."
  exit 1
fi

# Start process of creating an export.

curl -XPUT "${API_URL}/projects/${PROJECT_ID}/create-export" \
 -H "Authorization: Bearer ${TOKEN}"

# Retrieve the exports.

curl "${API_URL}/exports?filter%5Bproject%5D=${PROJECT_ID}" \
  -H "Authorization: Bearer ${TOKEN}" -o /tmp/exports.json

cat /tmp/exports.json | jq '.data[] | {id, "created-at": .attributes["created-at"], "completed-at": .attributes["completed-at"]}'

# When there is a completed-at, you can download it like this.

EXPORT_ID="GET FROM THE JSON FILE"

curl "${API_URL}/projects/${PROJECT_ID}$/download-export/${EXPORT_ID}" \
  -H "Authorization: Bearer ${TOKEN}" -o /tmp/export.zip
```
