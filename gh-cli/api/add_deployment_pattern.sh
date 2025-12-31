#!/bin/bash
set -euo pipefail

# Add custom deployment pattern (tag or branch)
# Usage: ./add_deployment_pattern.sh <repo> <env_name> [owner] [pattern] [pattern_type]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

REPO="${1:-}"
ENV_NAME="${2:-}"
OWNER="${3:-$ORG_NAME}"
PATTERN="${4:-$TAG_PATTERN}"
TYPE="${5:-$PATTERN_TYPE}"

if [ -z "$REPO" ] || [ -z "$ENV_NAME" ]; then
    log_error "Usage: $0 <repo> <env_name> [owner] [pattern] [pattern_type]"
    exit 1
fi

log_info "Adding deployment pattern for ${OWNER}/${REPO} env=${ENV_NAME}"
log_debug "Pattern: ${PATTERN}, Type: ${TYPE}"

log_api_call "POST" "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}/deployment-branch-policies"

if gh api \
    --method POST \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}/deployment-branch-policies" \
    -f "name=${PATTERN}" \
    -f "type=${TYPE}"; then
    log_success "Deployment pattern '${PATTERN}' (${TYPE}) added to ${OWNER}/${REPO} env=${ENV_NAME}"
else
    log_error "Failed to add deployment pattern for ${OWNER}/${REPO} env=${ENV_NAME}"
    exit 1
fi
