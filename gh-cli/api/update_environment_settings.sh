#!/bin/bash
set -euo pipefail

# Update environment settings with protection rules
# Usage: ./update_environment_settings.sh <repo> <env_name> [owner] [wait_timer] [reviewer_type] [reviewer_id]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

REPO="${1:-}"
ENV_NAME="${2:-}"
OWNER="${3:-$ORG_NAME}"
WAIT="${4:-$WAIT_TIMER}"
REV_TYPE="${5:-$REVIEWER_TYPE}"
REV_ID="${6:-$REVIEWER_ID}"

if [ -z "$REPO" ] || [ -z "$ENV_NAME" ]; then
    log_error "Usage: $0 <repo> <env_name> [owner] [wait_timer] [reviewer_type] [reviewer_id]"
    exit 1
fi

log_info "Updating environment settings for ${OWNER}/${REPO} env=${ENV_NAME}"
log_debug "Parameters: wait_timer=${WAIT}, reviewer=${REV_TYPE}:${REV_ID}"

BODY=$(cat <<EOF
{
    "wait_timer": ${WAIT},
    "deployment_branch_policy": {
        "protected_branches": ${PROTECTED_BRANCHES},
        "custom_branch_policies": ${CUSTOM_BRANCH_POLICIES}
    },
    "reviewers": [
        {
            "type": "${REV_TYPE}",
            "id": ${REV_ID}
        }
    ]
}
EOF
)

log_api_call "PUT" "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}"
log_debug "Request body: $BODY"

if echo "$BODY" | gh api \
    --method PUT \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "/repos/${OWNER}/${REPO}/environments/${ENV_NAME}" \
    --input -; then
    log_success "Environment settings updated for ${OWNER}/${REPO} env=${ENV_NAME}"
else
    log_error "Failed to update environment settings for ${OWNER}/${REPO} env=${ENV_NAME}"
    exit 1
fi
