# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository purpose

This is a scratch/learning repository that also hosts a working MuleSoft RTF (Runtime Fabric) CI/CD pipeline. The pipeline is the primary production-relevant work; the rest (`bash/`, `python/`, `terraform/`, etc.) is experimentation.

## Core CI/CD pipeline — MuleSoft RTF deploy

The deploy pipeline has three layers. Each layer can be found in:

| Layer | Location | Role |
|-------|----------|------|
| Properties file (base) | `<pom_path>/deploy-properties/<env>.properties` | App-level defaults and identity |
| Caller workflow | `.github/workflows/mule-rtf-deploy-action-caller.yml` | Org-wide resource standards per env tier; per-run overrides |
| Composite action | `.github/actions/mule-rtf-deploy/` | Builds and executes the Maven command |

**Override hierarchy (highest wins):**
1. Dispatch inputs passed at workflow trigger time
2. The `env-overrides` step's case statement in the caller (CPU/memory org standards per env)
3. The `.properties` file

**Key files:**
- `resolve_config.py` — reads the properties file, applies overrides from env vars, builds the `mvn package` command, writes it to `GITHUB_OUTPUT`
- `action.yml` — composite action: runs `resolve_config.py` (step 1), then `eval "$MVN_COMMAND"` (step 2)
- `mule-rtf-deploy-action-caller.yml` — caller; resolves resource limits then invokes the action

## Adding a new deploy property

There are three places to touch depending on whether the property should be overridable by the caller:

1. **Properties file only** — add `key=value` to `deploy-properties/<env>.properties`. It becomes `-Dkey=value` automatically. No other changes needed.

2. **Also overridable by caller** — additionally:
   - Add an input to `action.yml` (under `inputs:`)
   - Pass it as an env var in the `Build deploy command` step of `action.yml`
   - Add the `ENV_VAR → property.key` mapping to the `OVERRIDES` dict in `resolve_config.py`
   - Pass the input from the caller workflow to the action if the caller should control it

3. **Secret / credential** — add to `SECRET_ARGS` or `OPTIONAL_SECRET_ARGS` in `resolve_config.py` (never stored in `GITHUB_OUTPUT`, injected as `$SHELL_VAR` at eval time).

## Testing locally with `act`

```bash
# Run the RTF deploy caller workflow locally
act workflow_dispatch \
  -W .github/workflows/mule-rtf-deploy-action-caller.yml \
  --secret-file .github/act/.secrets \
  --eventpath .github/act/event-rtf-deploy.json
```

The `.github/act/.secrets` file holds test values for `CONNECTED_APP_CLIENT_ID`, `CONNECTED_APP_CLIENT_SECRET`, and `MULE_KEY`. The `.github/act/event-rtf-deploy.json` file holds sample dispatch inputs.

## ESB pipeline (separate)

`.github/workflows/esb-build.yml` and `esb-deploy.yml` are a separate pipeline for an EC2-based ESB. They use AWS SSM (`send-command`) to run shell commands on EC2 instances and S3 as an artifact transfer bucket. Infrastructure is managed via `terraform/main.tf`.

## Workflow file protection (merge strategy)

`.gitattributes` is configured so that `.github/workflows/**` always keeps this branch's version during a `git merge`. Changes to workflow files on incoming branches are silently dropped.

```
# .gitattributes
.github/workflows/** merge=ours
```

The merge driver must be registered once per local clone before it takes effect:

```bash
git config merge.ours.driver true
```

**Scope:** applies to `git merge` only. Does not protect against `git rebase`, `git cherry-pick`, or explicit `git checkout -- <file>`.

## Properties file format

```properties
# Comments are ignored
key=value          # becomes -Dkey=value in the Maven command
```

Values with spaces or special characters should be quoted: `key="val1,val2"`. The parser splits on the first `=` only, so values may contain `=`.
