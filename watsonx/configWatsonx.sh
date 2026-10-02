#!/usr/bin/env bash
# checkwatsonxkey.sh
# Configures WatsonX credentials in the Concert Openshift secret.
#
# expects environment the following environment variables defined in .watsonx.env:
# - WATSONX_API_KEY
# - WATSONX_API_PROJECT_ID
# - WATSONX_API_URL
#
# Usage: configWatsonx.sh [-f <env-file>]"
# -f points to a different file than .watsonx.env
#
# Author Markus W. Fehr
# September 17, 2026

# --- Resolve environment file ---
ENV_FILE=".watsonx.env"
CONCERT_NAMESPACE=ibm-concert

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f)
      ENV_FILE="$2"
      shift 2
      ;;
    *)
      echo "Usage: $0 [-f <env-file>]" >&2
      exit 1
      ;;
  esac
done

if [[ -n "$ENV_FILE" && "$ENV_FILE" != ".watsonx.env" ]]; then
  # Custom file specified via -f
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

# --- Validate required variables ---
MISSING=()
[[ -z "${WATSONX_API_KEY}" ]]        && MISSING+=("WATSONX_API_KEY")
[[ -z "${WATSONX_API_PROJECT_ID}" ]] && MISSING+=("WATSONX_API_PROJECT_ID")
[[ -z "${WATSONX_API_URL}" ]]        && MISSING+=("WATSONX_API_URL")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Error: the following variables are not set: ${MISSING[*]}" >&2
  echo "  Set them in '.watsonx.env' (or supply a file with -f <filename>)," >&2
  echo "  or export them as environment variables before running this script." >&2
  exit 1
fi

# --- Check kubectl availability ---
if ! command -v kubectl &>/dev/null; then
  echo "Error: 'kubectl' not found in PATH. Install kubectl and ensure it is on your PATH." >&2
  exit 1
fi

# --- Check OpenShift login (oc whoami via kubectl auth) ---
if ! kubectl auth whoami &>/dev/null 2>&1; then
  # Fallback: try a lightweight API call that requires authentication
  if ! kubectl get --raw /apis &>/dev/null 2>&1; then
    echo "Error: not logged in to OpenShift / Kubernetes cluster." >&2
    echo "  Run 'oc login <cluster-url>' or set a valid KUBECONFIG before running this script." >&2
    exit 1
  fi
fi


kubectl patch secret/app-cfg-secret -n $CONCERT_NAMESPACE --type=merge -p '{
   "data": {
   "WATSONX_API_KEY": "'$(echo -n $WATSONX_API_KEY | base64 )'",
   "WATSONX_API_PROJECT_ID": "'$(echo -n "$WATSONX_API_PROJECT_ID" | base64 )'",
   "WATSONX_API_URL": "'$(echo -n "$WATSONX_API_URL" | base64 )'"
   }
}'
kubectl rollout restart -n $CONCERT_NAMESPACE deployment/roja-py-utils


