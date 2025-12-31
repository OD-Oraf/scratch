#!/bin/bash

# Logging utilities for gh-cli API scripts

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    NC=''
fi

# Timestamp
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Log levels
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(timestamp) $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $(timestamp) $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(timestamp) $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(timestamp) $*" >&2
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        echo -e "${CYAN}[DEBUG]${NC} $(timestamp) $*"
    fi
}

# Log API call details
log_api_call() {
    local method="$1"
    local endpoint="$2"
    log_info "API ${method} ${endpoint}"
}

# Log API response
log_api_response() {
    local status="$1"
    if [ "$status" -eq 0 ]; then
        log_success "API call successful"
    else
        log_error "API call failed with exit code: $status"
    fi
}
