#!/bin/bash
set -euo pipefail

# List organization repositories
# Usage: ./list_repositories.sh [org] [per_page] [page]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

ORG="${1:-$ORG_NAME}"
PER_PAGE="${2:-30}"
PAGE="${3:-1}"

log_info "Listing repositories for organization: ${ORG} (page=${PAGE}, per_page=${PER_PAGE})"
log_api_call "GET" "/orgs/${ORG}/repos?per_page=${PER_PAGE}&page=${PAGE}"

if gh api \
  -H "${API_ACCEPT}" \
  -H "${API_VERSION}" \
  "/orgs/${ORG}/repos?per_page=${PER_PAGE}&page=${PAGE}&sort=full_name&direction=asc"; then
    log_success "Retrieved repositories for ${ORG} (page ${PAGE})"
else
    log_error "Failed to list repositories for ${ORG}"
    exit 1
fi
