#!/bin/bash
set -euo pipefail

# Update (or create) a workflow file in a single repository.
# Usage: ./update_workflow_single_repo.sh <local_workflow_file> <repo> [workflow_path] [--dry-run]
#
# Arguments:
#   local_workflow_file : path to the local workflow YAML to push
#   repo                : target repository in owner/repo or just repo (uses default owner from params.sh)
#   workflow_path       : destination path in repo (default: .github/workflows/<filename>)
#   --dry-run           : show what would happen without making changes
#
# Examples:
#   ./update_workflow_single_repo.sh ./ci.yml my-repo
#   ./update_workflow_single_repo.sh ../../.github/workflow-templates/non-prod-template.yml OD-ORAF/scratch .github/workflows/np_template.yml
#   ./update_workflow_single_repo.sh ./ci.yml my-repo .github/workflows/ci.yml --dry-run

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

# --------------- arguments ---------------
LOCAL_FILE="${1:?Usage: $0 <local_workflow_file> <repo> [workflow_path] [--dry-run]}"
REPO_ARG="${2:?Usage: $0 <local_workflow_file> <repo> [workflow_path] [--dry-run]}"
WORKFLOW_PATH="${3:-.github/workflows/$(basename "$LOCAL_FILE")}"
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
    esac
done

# Resolve owner/repo — accept either "repo" or "owner/repo"
if [[ "$REPO_ARG" == */* ]]; then
    FULL_REPO="$REPO_ARG"
else
    FULL_REPO="${ORG_NAME}/${REPO_ARG}"
fi

# --------------- validations ---------------
if [ ! -f "$LOCAL_FILE" ]; then
    log_error "File not found: $LOCAL_FILE"
    exit 1
fi

CONTENT_BASE64=$(base64 < "$LOCAL_FILE")
COMMIT_MSG="chore: update ${WORKFLOW_PATH} via automation"

log_info "Workflow file  : $LOCAL_FILE"
log_info "Destination    : $WORKFLOW_PATH"
log_info "Repository     : $FULL_REPO"
log_info "Dry run        : $DRY_RUN"

# --------------- dry-run ---------------
if [ "$DRY_RUN" = true ]; then
    log_info "[dry-run] Would update ${WORKFLOW_PATH} in ${FULL_REPO}"
    exit 0
fi

# --------------- update ---------------
# Check if the file already exists to get its SHA (required for updates)
FILE_SHA=""
EXISTING=$(gh api \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    "repos/${FULL_REPO}/contents/${WORKFLOW_PATH}" 2>/dev/null || true)

if [ -n "$EXISTING" ]; then
    FILE_SHA=$(echo "$EXISTING" | jq -r '.sha // empty')
fi

BODY=$(jq -n \
    --arg message "$COMMIT_MSG" \
    --arg content "$CONTENT_BASE64" \
    --arg sha "$FILE_SHA" \
    'if $sha == "" then {message: $message, content: $content}
     else {message: $message, content: $content, sha: $sha} end')

if gh api \
    -X PUT \
    -H "${API_ACCEPT}" \
    -H "${API_VERSION}" \
    --input - \
    "repos/${FULL_REPO}/contents/${WORKFLOW_PATH}" <<< "$BODY" > /dev/null 2>&1; then
    log_success "Updated ${WORKFLOW_PATH} in ${FULL_REPO}"
else
    log_error "Failed to update ${FULL_REPO}"
    exit 1
fi