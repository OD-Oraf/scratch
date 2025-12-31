#!/bin/bash

# Source parameters
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/params.sh"

# Ensure gh CLI is available
ensure_gh_available() {
    if ! command -v gh &> /dev/null; then
        echo "ERROR: GitHub CLI 'gh' not found on PATH." >&2
        return 1
    fi
    gh --version > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to execute 'gh --version'." >&2
        return 1
    fi
    echo "OK: gh CLI is available"
    return 0
}

# Ensure gh CLI is authenticated
ensure_gh_authed() {
    gh auth status > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "ERROR: Not authenticated with GitHub CLI. Run: gh auth login" >&2
        return 1
    fi
    echo "OK: gh CLI is authenticated"
    return 0
}

# Check auth status and get user info
check_auth_status() {
    gh api \
        -H "${API_ACCEPT}" \
        -H "${API_VERSION}" \
        /user
}

# List organization members
list_org_members() {
    local org="${1:-$ORG_NAME}"
    gh api \
        -H "${API_ACCEPT}" \
        -H "${API_VERSION}" \
        "/orgs/${org}/members"
}

# List organization teams
list_org_teams() {
    local org="${1:-$ORG_NAME}"
    gh api \
        -H "${API_ACCEPT}" \
        -H "${API_VERSION}" \
        "/orgs/${org}/teams"
}

# Create environment
create_environment() {
    local owner="${1:-$ORG_NAME}"
    local repo="$2"
    local env_name="$3"
    
    if [ -z "$repo" ] || [ -z "$env_name" ]; then
        echo "ERROR: Usage: create_environment [owner] <repo> <env_name>" >&2
        return 1
    fi
    
    gh api \
        -X PUT \
        "/repos/${owner}/${repo}/environments/${env_name}"
}

# Update environment settings with protection rules
update_environment_settings() {
    local owner="${1:-$ORG_NAME}"
    local repo="$2"
    local env_name="$3"
    local wait_timer="${4:-$WAIT_TIMER}"
    local reviewer_type="${5:-$REVIEWER_TYPE}"
    local reviewer_id="${6:-$REVIEWER_ID}"
    
    if [ -z "$repo" ] || [ -z "$env_name" ]; then
        echo "ERROR: Usage: update_environment_settings [owner] <repo> <env_name> [wait_timer] [reviewer_type] [reviewer_id]" >&2
        return 1
    fi
    
    local body=$(cat <<EOF
{
    "wait_timer": ${wait_timer},
    "deployment_branch_policy": {
        "protected_branches": ${PROTECTED_BRANCHES},
        "custom_branch_policies": ${CUSTOM_BRANCH_POLICIES}
    },
    "reviewers": [
        {
            "type": "${reviewer_type}",
            "id": ${reviewer_id}
        }
    ]
}
EOF
)
    
    echo "$body" | gh api \
        --method PUT \
        -H "${API_ACCEPT}" \
        -H "${API_VERSION}" \
        "/repos/${owner}/${repo}/environments/${env_name}" \
        --input -
}

# Add custom deployment pattern (tag or branch)
add_custom_deployment_pattern() {
    local owner="${1:-$ORG_NAME}"
    local repo="$2"
    local env_name="$3"
    local pattern="${4:-$TAG_PATTERN}"
    local pattern_type="${5:-$PATTERN_TYPE}"
    
    if [ -z "$repo" ] || [ -z "$env_name" ]; then
        echo "ERROR: Usage: add_custom_deployment_pattern [owner] <repo> <env_name> [pattern] [pattern_type]" >&2
        return 1
    fi
    
    gh api \
        --method POST \
        -H "${API_ACCEPT}" \
        -H "${API_VERSION}" \
        "/repos/${owner}/${repo}/environments/${env_name}/deployment-branch-policies" \
        -f "name=${pattern}" \
        -f "type=${pattern_type}"
}

# Main execution function - mirrors the Python main()
run_all() {
    echo "=== Checking gh CLI ==="
    ensure_gh_available || return 2
    ensure_gh_authed || return 2
    
    local failures=()
    
    echo ""
    echo "=== Creating environments ==="
    for repo in $REPOSITORIES; do
        for env_name in $ENV_NAMES; do
            echo -n "Creating ${ORG_NAME}/${repo} env=${env_name}... "
            if create_environment "$ORG_NAME" "$repo" "$env_name" > /dev/null 2>&1; then
                echo "OK"
            else
                echo "FAIL"
                failures+=("${repo}:${env_name}")
            fi
        done
    done
    
    echo ""
    echo "=== Updating environment settings ==="
    for repo in $REPOSITORIES; do
        for env_name in $ENV_NAMES; do
            echo -n "Updating ${ORG_NAME}/${repo} env=${env_name}... "
            if update_environment_settings "$ORG_NAME" "$repo" "$env_name" > /dev/null 2>&1; then
                echo "UPDATED"
            else
                echo "FAIL"
            fi
            
            echo -n "Adding pattern ${ORG_NAME}/${repo} env=${env_name} pattern=${TAG_PATTERN}... "
            if add_custom_deployment_pattern "$ORG_NAME" "$repo" "$env_name" > /dev/null 2>&1; then
                echo "OK"
            else
                echo "FAIL"
            fi
        done
    done
    
    if [ ${#failures[@]} -gt 0 ]; then
        echo ""
        echo "Some environments failed to create:"
        for f in "${failures[@]}"; do
            echo "  - ${ORG_NAME}/${f}"
        done
        return 1
    fi
    
    return 0
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all
fi
