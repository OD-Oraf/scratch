#!/bin/bash
set -euo pipefail

# Check auth status and get user info
# Usage: ./check_auth_status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

log_info "Checking authentication status"
log_api_call "GET" "/user"

if gh api \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    /user; then
    log_success "Authentication verified"
else
    log_error "Failed to verify authentication"
    exit 1
fi
