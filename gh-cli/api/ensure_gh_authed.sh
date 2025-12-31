#!/bin/bash
set -euo pipefail

# Ensure gh CLI is authenticated
# Usage: ./ensure_gh_authed.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logging.sh"

log_info "Checking gh CLI authentication status"

if ! gh auth status > /dev/null 2>&1; then
    log_error "Not authenticated with GitHub CLI. Run: gh auth login"
    exit 1
fi

log_success "gh CLI is authenticated"
gh auth status
