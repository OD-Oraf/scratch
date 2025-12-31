#!/bin/bash
set -euo pipefail

# Ensure gh CLI is available
# Usage: ./ensure_gh_available.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/logging.sh"

log_info "Checking if gh CLI is available"

if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI 'gh' not found on PATH"
    exit 1
fi

if ! gh --version > /dev/null 2>&1; then
    log_error "Failed to execute 'gh --version'"
    exit 1
fi

log_success "gh CLI is available"
gh --version
