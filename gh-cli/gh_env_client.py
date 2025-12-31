#!/usr/bin/env python3

import json
import subprocess
import sys
from typing import Any, Dict, List, Optional, Tuple


ENV_NAMES = [
    "dev",
    "staging",
    "production"
]

ORG_NAME = "OD-ORAF"
REPOSITORIES = [
    "scratch"
]

ENV_REVIEWERS = {
    "dev": [],  # No reviewers for dev
    "staging": [{"type": "User", "id": 43830269}],
    "production": [
        {"type": "User", "id": 43830269},
        {"type": "Team", "id": 12345}  # Add more for prod
    ]
}

#############################
# Functions                #
#############################
def _ensure_gh_available() -> None:
    try:
        subprocess.run(["gh", "--version"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except FileNotFoundError as e:
        raise RuntimeError("GitHub CLI 'gh' not found on PATH.") from e
    except subprocess.CalledProcessError as e:
        raise RuntimeError("Failed to execute 'gh --version'.") from e


def _ensure_gh_authed() -> None:
    # `gh auth status` returns non-zero when not authenticated.
    try:
        subprocess.run(["gh", "auth", "status"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e:
        raise RuntimeError("Not authenticated with GitHub CLI. Run: gh auth login") from e


def _create_environment(org: str, repo: str, env_name: str) -> Tuple[bool, str]:
    endpoint = f"/repos/{org}/{repo}/environments/{env_name}"
    cmd = ["gh", "api", "-X", "PUT", endpoint]

    process_result = subprocess.run(cmd, text=True, capture_output=True)
    if process_result.returncode == 0:
        return True, process_result.stdout.strip()

    err = (process_result.stderr or process_result.stdout).strip()
    if not err:
        err = f"gh api exited with code {process_result.returncode}"
    return False, err


def check_auth_status() -> Tuple[bool, Optional[Dict[str, Any]], Optional[str]]:
    cmd = [
        "gh", "api",
        "-H", "Accept: application/vnd.github+json",
        "-H", "X-GitHub-Api-Version: 2022-11-28",
        "/user"
    ]
    
    process_result = subprocess.run(cmd, text=True, capture_output=True)
    if process_result.returncode == 0:
        try:
            data = json.loads(process_result.stdout)
            return True, data, None
        except json.JSONDecodeError as e:
            return False, None, f"Failed to parse JSON: {e}"
    
    err = (process_result.stderr or process_result.stdout).strip()
    if not err:
        err = f"gh api exited with code {process_result.returncode}"
    return False, None, err


def list_org_members(org: str) -> Tuple[bool, Optional[List[Dict[str, Any]]], Optional[str]]:
    cmd = [
        "gh", "api",
        "-H", "Accept: application/vnd.github+json",
        "-H", "X-GitHub-Api-Version: 2022-11-28",
        f"/orgs/{org}/members"
    ]
    
    process_result = subprocess.run(cmd, text=True, capture_output=True)
    if process_result.returncode == 0:
        try:
            data = json.loads(process_result.stdout)
            return True, data, None
        except json.JSONDecodeError as e:
            return False, None, f"Failed to parse JSON: {e}"
    
    err = (process_result.stderr or process_result.stdout).strip()
    if not err:
        err = f"gh api exited with code {process_result.returncode}"
    return False, None, err


def list_org_teams(org: str) -> Tuple[bool, Optional[List[Dict[str, Any]]], Optional[str]]:
    cmd = [
        "gh", "api",
        "-H", "Accept: application/vnd.github+json",
        "-H", "X-GitHub-Api-Version: 2022-11-28",
        f"/orgs/{org}/teams"
    ]
    
    process_result = subprocess.run(cmd, text=True, capture_output=True)
    if process_result.returncode == 0:
        try:
            data = json.loads(process_result.stdout)
            return True, data, None
        except json.JSONDecodeError as e:
            return False, None, f"Failed to parse JSON: {e}"
    
    err = (process_result.stderr or process_result.stdout).strip()
    if not err:
        err = f"gh api exited with code {process_result.returncode}"
    return False, None, err


def update_environment_settings(
    owner: str,
    repo: str,
    environment_name: str,
    wait_timer: int = 0,
    prevent_self_review: bool = False,
    reviewers: Optional[List[Dict[str, Any]]] = None
) -> Tuple[bool, Optional[Dict[str, Any]], Optional[str]]:
    api_url = f"/repos/{owner}/{repo}/environments/{environment_name}"

    # API Request Body
    body = {
        "wait_timer": 0,
        "deployment_branch_policy": {
            "protected_branches": False,
            "custom_branch_policies": True
        }
    }
    if prevent_self_review:
        body["prevent_self_review"] = prevent_self_review
    if reviewers:
        body["reviewers"] = reviewers

    # API Request via GH CL
    cmd = [
        "gh", "api",
        "--method", "PUT",
        "-H", "Accept: application/vnd.github+json",
        "-H", "X-GitHub-Api-Version: 2022-11-28",
        api_url
    ]
    
    if body:
        cmd.extend(["--input", "-"])

    # Run as Python subprocess
    process_result = subprocess.run(
        cmd,
        text=True,
        capture_output=True,
        input=json.dumps(body) if body else None
    )
    
    if process_result.returncode == 0:
        try:
            data = json.loads(process_result.stdout) if process_result.stdout.strip() else {}
            return True, data, None
        except json.JSONDecodeError as e:
            return False, None, f"Failed to parse JSON: {e}"
    
    err = (process_result.stderr or process_result.stdout).strip()
    if not err:
        err = f"gh api exited with code {process_result.returncode}"
    return False, None, err

def add_custom_deployment_pattern(
    owner: str,
    repo: str,
    environment_name: str,
    pattern: str,
    pattern_type: str = "tag"
) -> Tuple[bool, Optional[Dict[str, Any]], Optional[str]]:
    api_url = f"/repos/{owner}/{repo}/environments/{environment_name}/deployment-branch-policies"
    
    # API Request via GH CLI using -f flags
    cmd = [
        "gh", "api",
        "--method", "POST",
        "-H", "Accept: application/vnd.github+json",
        "-H", "X-GitHub-Api-Version: 2022-11-28",
        api_url,
        "-f", f"name={pattern}",
        "-f", f"type={pattern_type}"
    ]
    
    # Run as Python subprocess
    process_result = subprocess.run(
        cmd,
        text=True,
        capture_output=True
    )
    
    if process_result.returncode == 0:
        try:
            data = json.loads(process_result.stdout) if process_result.stdout.strip() else {}
            return True, data, None
        except json.JSONDecodeError as e:
            return False, None, f"Failed to parse JSON: {e}"
    
    err = (process_result.stderr or process_result.stdout).strip()
    if not err:
        err = f"gh api exited with code {process_result.returncode}"
    return False, None, err


#############################
# Main Method           #
#############################


def main() -> int:
    # Check  ENV name and existence of GH CLI
    if not ENV_NAMES:
        print("ERROR: ENV_NAMES is empty", file=sys.stderr)
        return 2

    try:
        _ensure_gh_available()
        _ensure_gh_authed()
    except RuntimeError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2

    if not REPOSITORIES:
        print("ERROR: REPOSITORIES is empty", file=sys.stderr)
        return 2

    if not ORG_NAME:
        print("ERROR: ORG_NAME is empty", file=sys.stderr)
        return 2

    failures: List[Tuple[str, str, str]] = []

    # Create all environments for each repository
    for repo in REPOSITORIES:
        repo = repo.strip()
        if not repo:
            continue
        
        for env_name in ENV_NAMES:
            env_name = env_name.strip()
            if not env_name:
                continue
                
            ok, msg = _create_environment(ORG_NAME, repo, env_name)
            if ok:
                print(f"OK   {ORG_NAME}/{repo}  env={env_name}")
            else:
                print(f"FAIL {ORG_NAME}/{repo}  env={env_name}  {msg}")
                failures.append((repo, env_name, msg))

    # Update environment settings for all environments
    reviewers = ENV_REVIEWERS.get(env_name, [])
    
    for repo in REPOSITORIES:
        repo = repo.strip()
        if not repo:
            continue
            
        for env_name in ENV_NAMES:
            env_name = env_name.strip()
            if not env_name:
                continue
                
            ok, data, err = update_environment_settings(
                ORG_NAME, repo, env_name, 
                wait_timer=0,
                reviewers=reviewers
            )
            if ok:
                print(f"UPDATED {ORG_NAME}/{repo}  env={env_name}")
            else:
                print(f"FAIL UPDATE {ORG_NAME}/{repo}  env={env_name}  {err}")
            
            # Add semantic versioning tag pattern
            ok_pattern, data_pattern, err_pattern = add_custom_deployment_pattern(
                ORG_NAME, repo, env_name,
                pattern="*.*.*",
                pattern_type="tag"
            )
            if ok_pattern:
                print(f"PATTERN ADDED {ORG_NAME}/{repo}  env={env_name}  pattern=*.*.*")
            else:
                print(f"FAIL PATTERN {ORG_NAME}/{repo}  env={env_name}  {err_pattern}")

    if failures:
        print("\nSome environments failed to create:")
        for repo, env_name, msg in failures:
            print(f"- {ORG_NAME}/{repo} env={env_name}: {msg}")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
