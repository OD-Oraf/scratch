#!/bin/bash

# Centralized parameters for gh cli scripts

# Organization
ORG_NAME="OD-ORAF"

# Repositories (space-separated)
REPOSITORIES="scratch"

# Environment names (space-separated)
ENV_NAMES="dev staging production"

# API Headers
API_ACCEPT="Accept: application/vnd.github+json"
API_VERSION="X-GitHub-Api-Version: 2022-11-28"

# Environment settings
WAIT_TIMER=0
PREVENT_SELF_REVIEW=false

# Reviewers (JSON format for API)
REVIEWER_TYPE="User"
REVIEWER_ID=43830269

# Deployment branch policy
TAG_PATTERN="*.*.*"
PATTERN_TYPE="tag"
PROTECTED_BRANCHES=false
CUSTOM_BRANCH_POLICIES=true
