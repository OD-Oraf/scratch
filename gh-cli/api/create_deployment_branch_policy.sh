#!/bin/bash
set -euo pipefail

# Create deployment branch policy
# Usage: ./create_deployment_branch_policy.sh <repo> <env_name> [owner] [tag_pattern]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

REPO="${1:-scratch}"
ENV_NAME="${2:-production}"
OWNER="${3:-$ORG_NAME}"
PATTERN="${4:-$TAG_PATTERN}"

log_info "Creating deployment branch policy for ${OWNER}/${REPO} env=${ENV_NAME}"
log_debug "Pattern: ${PATTERN}, Type: tag"

log_api_call "POST" "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}/deployment-branch-policies"

if gh api \
    --method POST \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}/deployment-branch-policies" \
    -f "name=${PATTERN}" \
    -f "type=tag"; then
    log_success "Deployment branch policy created for ${OWNER}/${REPO} env=${ENV_NAME}"
else
    log_error "Failed to create deployment branch policy for ${OWNER}/${REPO} env=${ENV_NAME}"
    exit 1
fi
