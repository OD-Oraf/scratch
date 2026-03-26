#!/bin/bash
set -euo pipefail

# Delete environment
# Usage: ./delete_environment.sh <repo> <env_name> [owner]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

REPO="${1:-}"
ENV_NAME="${2:-}"
OWNER="${3:-$ORG_NAME}"

if [ -z "$REPO" ] || [ -z "$ENV_NAME" ]; then
    log_error "Usage: $0 <repo> <env_name> [owner]"
    exit 1
fi

log_info "Deleting environment ${ENV_NAME} for ${OWNER}/${REPO}"

log_api_call "DELETE" "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}"

if gh api \
    -X DELETE \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}"; then
    log_success "Environment '${ENV_NAME}' deleted for ${OWNER}/${REPO}"
else
    log_error "Failed to delete environment '${ENV_NAME}' for ${OWNER}/${REPO}"
    exit 1
fi
