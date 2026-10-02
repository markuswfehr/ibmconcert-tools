#!/bin/bash
# checkwatsonxkey.sh
#
# Purpose: Check whether a given API Key exists. If found, show associated data to identify project IDs
#
# Author Markus W. Fehr
# September 17, 2026

# --- Resolve env file and API key ---
ENV_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f)
      ENV_FILE="$2"
      shift 2
      ;;
    -*)
      echo "Usage: $0 [-f <env-file>] [<API key>]" >&2
      exit 1
      ;;
    *)
      WATSONX_API_KEY="$1"
      shift
      ;;
  esac
done

if [[ -n "$ENV_FILE" ]]; then
  if [[ ! -r "$ENV_FILE" ]]; then
    echo "Error: cannot read file '$ENV_FILE'." >&2
    exit 1
  fi
  # shellcheck source=/dev/null
  source "$ENV_FILE"
 elif [[ -f ".watsonx.env" ]]; then
   # shellcheck source=/dev/null
   source ".watsonx.env"
fi

if [[ -z "${WATSONX_API_KEY}" ]]; then
  echo "" >&2
  echo "Error: WATSONX_API_KEY is not set." >&2
  echo "  Provide it as a positional argument, store it in '.watsonx.env'," >&2
  echo "  supply a file with -f <env-file>, or export it as an environment variable." >&2
  echo "" >&2
  echo "Usage: $0 [-f <env-file>] [<API key>]" >&2
  echo "" >&2
  exit 1
fi

API_KEY="${WATSONX_API_KEY}"

#
# part 1 - check if the API Key is found
#

echo ""
echo "Watsonx API Key validation"
echo ""

RESPONSE=$(curl -s -X POST \
https://iam.cloud.ibm.com/identity/token \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$API_KEY")

if echo "$RESPONSE" | jq -e '.access_token' > /dev/null 2>&1; then
  echo "Watsonx API Key $API_KEY found."
  echo ""
fi

if echo "$RESPONSE" | jq -e '.errorMessage' > /dev/null 2>&1; then
  echo "Watsonx API Key $API_KEY not found."
  echo ""
  echo "Detailed error message:"
  echo ""
  echo $RESPONSE | jq
  exit 1
fi

#
# part 2 - Read all projects associated to this API Key
#

IAM_TOKEN=$(echo "$RESPONSE" | jq -r .access_token)

PROJECTS=$(curl -s \
-H "Authorization: Bearer $IAM_TOKEN" \
"https://api.dataplatform.cloud.ibm.com/v2/projects?limit=100")

TOTAL=$(echo "$PROJECTS" | jq -r '.total_results')
echo "Projects found: $TOTAL"
echo ""

echo "$PROJECTS" | jq -r --arg api_key "$API_KEY" '
  .resources[] |
  "Project ID:  \(.metadata.guid)",
  "Name:        \(.entity.name)",
  "Description: \(.entity.description)",
  "Creator:     \(.entity.creator)",
  "Region:      \(.entity.storage.properties.bucket_region)",
  "",
  "export WATSONX_API_KEY=\($api_key)",
  "export WATSONX_API_PROJECT_ID=\(.metadata.guid)",
  "export WATSONX_API_URL=https://\(.entity.storage.properties.bucket_region).ml.cloud.ibm.com",
  ""
'


