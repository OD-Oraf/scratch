#!/bin/bash
set -euo pipefail

# gh repo list OD-Oraf --limit 100 --json name,url -q '.[] | select(.name | startswith("scratch"))'

# List organization teams
# Usage: ./list_org_teams.sh [org]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

ORG="${1:-$ORG_NAME}"

log_info "Listing teams for organization: ${ORG}"
log_api_call "GET" "/orgs/${ORG}/teams"

if gh repo list \
  "${ORG}" --limit 100 \
  --json name,url \
  -q '.[] | select(.name | startswith("scratch"))'; then
    log_success "Retrieved repositories for ${ORG}"
else
    log_error "Failed to list teams for ${ORG}"
    exit 1
fi
