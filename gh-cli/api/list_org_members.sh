#!/bin/bash
set -euo pipefail

# List organization members with optional login filter
# Usage: ./list_org_members.sh [org] [filter]
# Examples:
#   ./list_org_members.sh my-org           # list all members
#   ./list_org_members.sh my-org "pvs-"     # list members whose login starts with "pvs-"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

ORG="${1:-$ORG_NAME}"
FILTER="${2:-}"

if [[ -n "${FILTER}" ]]; then
    log_info "Listing members for organization: ${ORG} (filter: '${FILTER}')"
else
    log_info "Listing members for organization: ${ORG}"
fi
log_api_call "GET" "/orgs/${ORG}/members"

if RESULT=$(gh api \
    --paginate \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "orgs/${ORG}/members"); then
    if [[ -n "${FILTER}" ]]; then
        echo "${RESULT}" | jq --arg f "${FILTER}" '[.[] | select(.login | startswith($f))]'
    else
        echo "${RESULT}"
    fi
    log_success "Retrieved members for ${ORG}"
else
    log_error "Failed to list members for ${ORG}"
    exit 1
fi
