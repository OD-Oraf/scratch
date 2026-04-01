#!/bin/bash
set -euo pipefail

# Update (or create) a workflow file across all repositories you own.
# Usage: ./update_workflow_across_repos.sh <local_workflow_file> [workflow_path] [owner] [--search <query>] [--dry-run]
#
# Arguments:
#   local_workflow_file : path to the local workflow YAML to push
#   workflow_path       : destination path in each repo (default: .github/workflows/<filename>)
#   owner               : GitHub owner/org (default: from params.sh)
#   --search <query>    : only update repos matching this GitHub search query (e.g. "ecs-")
#   --dry-run           : list repos without making changes
#
# Examples:
#   ./update_workflow_across_repos.sh ./ci.yml
#   ./update_workflow_across_repos.sh ./ci.yml .github/workflows/ci.yml
#   ./update_workflow_across_repos.sh ./ci.yml .github/workflows/ci.yml OD-ORAF --dry-run
#   ./update_workflow_across_repos.sh ./ci.yml .github/workflows/ci.yml OD-ORAF --search "ecs-"
# bash update_workflow_across_repos.sh \ .github/workflows/basic-workflow.yaml \
  #    .github/workflows/basic-workflow.yaml \
  #    OD-ORAF

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"
source "${SCRIPT_DIR}/logging.sh"

# --------------- arguments ---------------
LOCAL_FILE="${1:?Usage: $0 <local_workflow_file> [workflow_path] [owner] [--dry-run]}"
WORKFLOW_PATH="${2:-.github/workflows/$(basename "$LOCAL_FILE")}"
OWNER="${3:-$ORG_NAME}"
DRY_RUN=false
SEARCH=""
args=("$@")
for ((i=0; i<${#args[@]}; i++)); do
    case "${args[$i]}" in
        --dry-run) DRY_RUN=true ;;
        --search)  SEARCH="${args[$((i+1))]}"; ((i++)) ;;
    esac
done

# --------------- validations ---------------
if [ ! -f "$LOCAL_FILE" ]; then
    log_error "File not found: $LOCAL_FILE"
    exit 1
fi

CONTENT_BASE64=$(base64 < "$LOCAL_FILE")
COMMIT_MSG="chore: update ${WORKFLOW_PATH} via automation"

log_info "Workflow file  : $LOCAL_FILE"
log_info "Destination    : $WORKFLOW_PATH"
log_info "Owner          : $OWNER"
log_info "Search filter  : ${SEARCH:-(none)}"
log_info "Dry run        : $DRY_RUN"

# --------------- list repos ---------------
# Search repositories using gh cli commands
if [ -n "$SEARCH" ]; then
    log_info "Searching repositories for '${SEARCH}' owned by ${OWNER}..."
    REPOS=$(gh search repos "$SEARCH" --owner "$OWNER" --limit 500 --json name --jq '.[].name')
else
    log_info "Fetching all repositories owned by ${OWNER}..."
    REPOS=$(gh repo list "$OWNER" --limit 500 --json name --jq '.[].name')
fi
# Error if no repositories found
if [ -z "$REPOS" ]; then
    log_warn "No repositories found for ${OWNER}"
    exit 0
fi

# Total repositories found
REPO_COUNT=$(echo "$REPOS" | wc -l | tr -d ' ')
log_info "Found ${REPO_COUNT} repositories"

# --------------- iterate ---------------
SUCCESS=0
SKIPPED=0
FAILED=0

for REPO in $REPOS; do
    FULL_REPO="${OWNER}/${REPO}"
    log_info "Processing ${FULL_REPO}..."

    if [ "$DRY_RUN" = true ]; then
        log_info "  [dry-run] Would update ${WORKFLOW_PATH} in ${FULL_REPO}"
        ((SKIPPED++))
        continue
    fi

    # Check if the file already exists to get its SHA (required for updates)
    FILE_SHA=""
    EXISTING=$(gh api \
        -H "${API_ACCEPT}" \
        -H "${API_VERSION}" \
        "repos/${FULL_REPO}/contents/${WORKFLOW_PATH}" 2>/dev/null || true)

    if [ -n "$EXISTING" ]; then
        FILE_SHA=$(echo "$EXISTING" | jq -r '.sha // empty')
    fi

    # Build the request body
    BODY=$(jq -n \
        --arg message "$COMMIT_MSG" \
        --arg content "$CONTENT_BASE64" \
        --arg sha "$FILE_SHA" \
        'if $sha == "" then {message: $message, content: $content}
         else {message: $message, content: $content, sha: $sha} end')

    # Update the file
    if gh api \
        -X PUT \
        -H "${API_ACCEPT}" \
        -H "${API_VERSION}" \
        --input - \
        "repos/${FULL_REPO}/contents/${WORKFLOW_PATH}" <<< "$BODY" > /dev/null 2>&1; then
        log_success "Updated ${WORKFLOW_PATH} in ${FULL_REPO}"
        ((SUCCESS++))
    else
        log_error "Failed to update ${FULL_REPO}"
        ((FAILED++))
    fi
done

# --------------- summary ---------------
echo ""
log_info "===== Summary ====="
log_info "Total  : ${REPO_COUNT}"
log_success "Updated: ${SUCCESS}"
if [ "$SKIPPED" -gt 0 ]; then
    log_info "Skipped: ${SKIPPED} (dry-run)"
fi
if [ "$FAILED" -gt 0 ]; then
    log_error "Failed : ${FAILED}"
fi
