#!/bin/bash
set -euo pipefail

# List organization repositories using gh search repos
# Usage: ./list_repositories.sh [org] [per_page] [page] [search] [slim]
# per_page: results per page, max 50 (default 30)
# page: page number (default 1)
# search: optional keyword to filter repository names
# slim: set to "true" to return only name and node_id (default: false)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

ORG="${1:-$ORG_NAME}"
PER_PAGE="${2:-30}"
PAGE="${3:-1}"
SEARCH="${4:-}"
SLIM="${5:-false}"

QUERY="org:${ORG}"
if [ -n "$SEARCH" ]; then
    QUERY="${SEARCH} in:name ${QUERY}"
fi

log_info "Searching repositories for owner: ${ORG} (page=${PAGE}, per_page=${PER_PAGE}, search=${SEARCH:-<none>})"

JQ_EXPR=".items"
if [ "$SLIM" = "true" ]; then
    JQ_EXPR="[.items[] | {name, node_id}]"
fi

if gh api \
  -H "${API_ACCEPT}" \
  -H "${API_VERSION}" \
  --jq "${JQ_EXPR}" \
  "/search/repositories?q=${QUERY// /+}&sort=name&order=asc&per_page=${PER_PAGE}&page=${PAGE}"; then
    log_success "Retrieved repositories for ${ORG} (page ${PAGE})"
else
    log_error "Failed to search repositories for ${ORG}"
    exit 1
fi
