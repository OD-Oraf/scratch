#!/bin/bash
set -euo pipefail

# List organization teams
# Usage: ./list_org_teams.sh [org]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

ORG="${1:-$ORG_NAME}"

log_info "Listing teams for organization: ${ORG}"
log_api_call "GET" "/orgs/${ORG}/teams"

if gh api \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "/orgs/${ORG}/teams"; then
    log_success "Retrieved teams for ${ORG}"
else
    log_error "Failed to list teams for ${ORG}"
    exit 1
fi
