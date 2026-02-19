#!/bin/bash
# Simple git clone with GitHub App token

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

REPO_URL="${GIT_URL}"
BRANCH="${GIT_BRANCH:-main}"
DEST="${GIT_DEST}"
INSTALLATION_ID="${GITHUB_APP_INSTALLATION_ID}"

# Get installation token via curl
TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Clone repo
REPO_PATH=$(echo "$REPO_URL" | sed 's|https://github.com/||' | sed 's|\.git$||')
AUTH_URL="https://x-access-token:${TOKEN}@github.com/${REPO_PATH}.git"

git clone --branch "$BRANCH" "$AUTH_URL" "$DEST"
