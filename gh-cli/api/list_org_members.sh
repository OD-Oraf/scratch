#!/bin/bash
set -euo pipefail

# List organization members
# Usage: ./list_org_members.sh [org]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

ORG="${1:-$ORG_NAME}"

log_info "Listing members for organization: ${ORG}"
log_api_call "GET" "/orgs/${ORG}/members"

if gh api \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "/orgs/${ORG}/members"; then
    log_success "Retrieved members for ${ORG}"
else
    log_error "Failed to list members for ${ORG}"
    exit 1
fi
