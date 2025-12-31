#!/bin/bash
set -euo pipefail

# Create environment
# Usage: ./create_environment.sh <repo> <env_name> [owner]

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

log_info "Creating environment ${ENV_NAME} for ${OWNER}/${REPO}"

log_api_call "PUT" "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}"

if gh api \
    -X PUT \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}"; then
    log_success "Environment '${ENV_NAME}' created for ${OWNER}/${REPO}"
else
    log_error "Failed to create environment '${ENV_NAME}' for ${OWNER}/${REPO}"
    exit 1
fi
