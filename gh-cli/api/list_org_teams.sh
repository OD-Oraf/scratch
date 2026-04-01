#!/bin/bash
set -euo pipefail

# List organization teams with optional name filter
# Usage: ./list_org_teams.sh [org] [filter]
# Examples:
#   ./list_org_teams.sh my-org           # list all teams
#   ./list_org_teams.sh my-org "pvs-"     # list teams whose name starts with "pvs-"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

ORG="${1:-$ORG_NAME}"
FILTER="${2:-}"

if [[ -n "${FILTER}" ]]; then
    log_info "Listing teams for organization: ${ORG} (filter: '${FILTER}')"
else
    log_info "Listing teams for organization: ${ORG}"
fi
log_api_call "GET" "/orgs/${ORG}/teams"

JQ_FILTER="."
if [[ -n "${FILTER}" ]]; then
    JQ_FILTER="[.[] | select(.name | startswith(\"${FILTER}\"))]"
fi

if gh api \
    --paginate \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    --jq "${JQ_FILTER}" \
    "orgs/${ORG}/teams"; then
    log_success "Retrieved teams for ${ORG}"
else
    log_error "Failed to list teams for ${ORG}"
    exit 1
fi
