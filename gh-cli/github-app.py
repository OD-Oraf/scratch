#!/Users/od/Documents/scratch/gh-cli/venv/bin/python
"""
Simple GitHub App Clone Script

Clones a repository using GitHub App authentication.
Just set the configuration variables below and run: python github-app.py
"""

import sys
import time
import subprocess

import jwt
import requests


# =============================================================================
# CONFIGURATION - Update these values
# =============================================================================
GITHUB_APP_ID = "1365153"
GITHUB_APP_PRIVATE_KEY_PATH = "./od-oraf-test-app.2026-01-13.private-key.pem"  # Path to your .pem file
GITHUB_APP_INSTALLATION_ID = "69770355"
GIT_URL = "https://github.com/OD-Oraf/scratch"
CLONE_DEST = ""  # Optional: destination folder (leave empty for repo name)
# =============================================================================


def get_installation_token():
    """Generate JWT and get installation access token."""
    with open(GITHUB_APP_PRIVATE_KEY_PATH, "r") as f:
        private_key = f.read()

    now = int(time.time())
    payload = {
        "iat": now - 60,
        "exp": now + (10 * 60),
        "iss": GITHUB_APP_ID,
    }
    jwt_token = jwt.encode(payload, private_key, algorithm="RS256")

    headers = {
        "Authorization": f"Bearer {jwt_token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    }

    url = f"https://api.github.com/app/installations/{GITHUB_APP_INSTALLATION_ID}/access_tokens"
    response = requests.post(url, headers=headers)
    response.raise_for_status()

    return response.json()["token"]


def clone_repo():
    """Clone the repository using GitHub App token."""
    # Validate config
    if not GITHUB_APP_PRIVATE_KEY_PATH:
        print("Error: GITHUB_APP_PRIVATE_KEY_PATH not set", file=sys.stderr)
        sys.exit(1)

    # Get token
    print("Getting installation token...")
    token = get_installation_token()

    # Build authenticated URL
    repo_path = GIT_URL.replace("https://github.com/", "").replace(".git", "")
    auth_url = f"https://x-access-token:{token}@github.com/{repo_path}.git"

    # Determine destination
    dest = CLONE_DEST if CLONE_DEST else repo_path.split("/")[-1]

    # Clone
    print(f"Cloning {GIT_URL} to {dest}...")
    result = subprocess.run(
        ["git", "clone", auth_url, dest],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print(f"Clone failed: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    print(f"Successfully cloned to {dest}")


if __name__ == "__main__":
    installation_token = get_installation_token()
    print(installation_token)
    # clone_repo()
