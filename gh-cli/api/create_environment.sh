#!/bin/bash
set -euo pipefail

# Create environment with optional required reviewers and prevent-self-review
# Usage: ./create_environment.sh <repo> <env_name> [owner] [reviewer_user_ids]
# reviewer_user_ids: comma-separated list of GitHub user IDs (e.g. "123,456,789")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

REPO="${1:-}"
ENV_NAME="${2:-}"
OWNER="${3:-$ORG_NAME}"
REVIEWER_IDS="${4:-}"

if [ -z "$REPO" ] || [ -z "$ENV_NAME" ]; then
    log_error "Usage: $0 <repo> <env_name> [owner]"
    exit 1
fi

# Build reviewers JSON array from comma-separated user IDs
REVIEWERS_JSON="[]"
if [ -n "$REVIEWER_IDS" ]; then
    REVIEWERS_JSON=$(echo "$REVIEWER_IDS" | tr ',' '\n' | while read -r uid; do
        uid=$(echo "$uid" | xargs)
        [ -n "$uid" ] && echo "{\"type\":\"Team\",\"id\":${uid}}"
    done | paste -sd ',' - | sed 's/^/[/;s/$/]/')
    log_info "Adding reviewers: ${REVIEWERS_JSON}"
fi

BODY=$(cat <<EOF
{
  "prevent_self_review": true,
  "reviewers": ${REVIEWERS_JSON}
}
EOF
)

log_info "Creating environment ${ENV_NAME} for ${OWNER}/${REPO}"

log_api_call "PUT" "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}"

if gh api \
    --method PUT \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "repos/${OWNER}/${REPO}/environments/${ENV_NAME}" \
    --input - <<< "${BODY}"; then
    log_success "Environment '${ENV_NAME}' created for ${OWNER}/${REPO}"
else
    log_error "Failed to create environment '${ENV_NAME}' for ${OWNER}/${REPO}"
    exit 1
fi
