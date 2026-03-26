#!/bin/bash
set -euo pipefail

# List organization repositories using gh search repos
# Usage: ./list_repositories.sh [org] [per_page] [page] [search]
# per_page: results per page, max 50 (default 30)
# page: page number (default 1)
# search: optional keyword to filter repository names

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

ORG="${1:-$ORG_NAME}"
PER_PAGE="${2:-30}"
PAGE="${3:-1}"
SEARCH="${4:-}"

QUERY="org:${ORG}"
if [ -n "$SEARCH" ]; then
    QUERY="${SEARCH} in:name ${QUERY}"
fi

log_info "Searching repositories for owner: ${ORG} (page=${PAGE}, per_page=${PER_PAGE}, search=${SEARCH:-<none>})"

if gh api \
  -H "${API_ACCEPT}" \
  -H "${API_VERSION}" \
  --jq ".items" \
  "/search/repositories?q=${QUERY// /+}&sort=name&order=asc&per_page=${PER_PAGE}&page=${PAGE}"; then
    log_success "Retrieved repositories for ${ORG} (page ${PAGE})"
else
    log_error "Failed to search repositories for ${ORG}"
    exit 1
fi
