#!/bin/bash
# Simple git push with GitHub App token

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

REPO_PATH="${GIT_DEST}"
COMMIT_MESSAGE="${COMMIT_MESSAGE:-Auto-commit via GitHub App}"
BRANCH="${GIT_BRANCH:-main}"
INSTALLATION_ID="${GITHUB_APP_INSTALLATION_ID}"

# Get installation token via curl
TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens" | grep -o '"token":"[^"]*' | cut -d'"' -f4)

cd "$REPO_PATH"

git config user.name "github-app[bot]"
git config user.email "github-app[bot]@users.noreply.github.com"

REMOTE_URL=$(git remote get-url origin)
REPO_PATH_EXTRACTED=$(echo "$REMOTE_URL" | sed -E 's#https?://[^@]*@?github.com/##' | sed 's/.git$//')
AUTH_URL="https://x-access-token:${TOKEN}@github.com/${REPO_PATH_EXTRACTED}.git"

git remote set-url origin "$AUTH_URL"
git add .
git commit -m "$COMMIT_MESSAGE" || true
git push origin "$BRANCH"
