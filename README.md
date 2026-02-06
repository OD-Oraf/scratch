# Scratch Repository

A collection of utilities, learning materials, and project examples.

## Repository Organization Proposal

This repository has become disorganized over time. Below are the proposed changes to improve structure and maintainability.

---

### Critical Issues to Address

#### 1. Remove Duplicate Content
- **Issue:** `gh-cli/scratch/` contains an 11MB duplicate of the entire repository root
- **Action:** Delete `gh-cli/scratch/` directory entirely

#### 2. Remove Committed Virtual Environment
- **Issue:** `venv/` directory (76MB) is tracked in git
- **Action:** Remove from git history using `git filter-branch` or BFG Repo-Cleaner
- **Action:** Add `venv/` to `.gitignore`

#### 3. Secure Sensitive Files
- **Issue:** Private keys and credentials exposed in `gh-cli/`
  - `.env`
  - `*.pem` (private key files)
  - `*.b64` (base64 encoded keys)
- **Action:** Remove these files from the repository
- **Action:** Add to `.gitignore`:
  ```
  .env
  *.pem
  *.b64
  ```
- **Action:** Use GitHub Secrets or a secrets manager for credentials

---

### Proposed Directory Structure

```
scratch/
├── automation/          # GitHub CLI tools and workflows
│   ├── api/             # GitHub API scripts
│   ├── workflows/       # Reusable workflow components
│   └── github-app/      # GitHub App utilities
│
├── learning/            # Educational materials and exercises
│   ├── bash/            # Bash scripting exercises
│   └── oas-examples/    # OpenAPI specification examples
│
├── projects/            # Application code by language
│   ├── java/
│   ├── python/
│   └── swift/
│
├── tests/               # Test scripts (moved from root)
│   ├── test_parser.py
│   └── test_consolidated_parser.py
│
├── .github/             # GitHub Actions workflows
├── .gitignore
└── README.md
```

---

### Files to Clean Up

| File | Location | Action |
|------|----------|--------|
| `confluence-content-preview.html` | root | Delete (generated output) |
| `confluence-content-test.html` | root | Delete (generated output) |
| `changes-preview.json` | root | Delete (generated output) |
| `changes-test.json` | root | Delete (generated output) |
| `ex.txt` | root | Delete (placeholder) |
| `example` | root | Delete (placeholder) |
| `test_parser.py` | root | Move to `tests/` |
| `test_consolidated_parser.py` | root | Move to `tests/` |

---

### .gitignore Additions

Add the following to `.gitignore`:

```gitignore
# Virtual environments
venv/
.venv/
env/

# Secrets and credentials
.env
*.pem
*.b64
*.key

# Generated files
*.log
.DS_Store

# IDE
.idea/
.vscode/
*.swp
```

---

### Size Impact

| Before | After (estimated) |
|--------|-------------------|
| ~135MB | ~15-20MB |

Removing `venv/` (76MB) and `gh-cli/scratch/` (11MB) will significantly reduce repository size.

---

## Current Contents

| Directory | Description |
|-----------|-------------|
| `bash/` | Bash scripting exercises and sample data |
| `python/` | Python utilities (API tools, scrapers, Lambda examples) |
| `java/` | Java project configurations |
| `swift/` | iOS/macOS Swift projects |
| `oas-examples/` | OpenAPI/Swagger specification examples |
| `gh-cli/` | GitHub CLI and API utilities |
| `.github/` | GitHub Actions workflows |

---

## References

- [CVE-2025-41249](https://spring.io/security/cve-2025-41249) - Snyk vulnerability notes