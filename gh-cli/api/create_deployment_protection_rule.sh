#!/bin/bash
set -euo pipefail

# Create deployment protection rule
# Usage: ./create_deployment_protection_rule.sh <repo> <env_name> [owner]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

REPO="${1:-scratch}"
ENV_NAME="${2:-production}"
OWNER="${3:-$ORG_NAME}"

log_info "Creating deployment protection rule for ${OWNER}/${REPO} env=${ENV_NAME}"

log_api_call "POST" "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}/deployment_protection_rules"

if gh api \
    --method POST \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}/deployment_protection_rules" \
    -F "*.*.*"; then
    log_success "Deployment protection rule created for ${OWNER}/${REPO} env=${ENV_NAME}"
else
    log_error "Failed to create deployment protection rule for ${OWNER}/${REPO} env=${ENV_NAME}"
    exit 1
fi
