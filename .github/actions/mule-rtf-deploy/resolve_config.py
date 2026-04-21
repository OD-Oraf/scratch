"""
Build a Maven deploy command from a deploy-config properties file.

The properties file supplies all Maven -D flags (key=value).
The action caller can override any property via action inputs
(org/env-specific values common across all applications).

Secrets are injected as shell variable references so they never
appear in GITHUB_OUTPUT — resolved at execution time via env vars.
"""

import os
import pathlib
import sys


# ── Caller overrides: env var → properties-file key ──────────────────────
# Ref: https://docs.mulesoft.com/mule-runtime/latest/deploy-to-rtf
OVERRIDES = {
    # Top-level runtimeFabricDeployment parameters
    "ANYPOINT_URI":              "anypoint.uri",
    "ANYPOINT_ENVIRONMENT":      "anypoint.environment",
    "ANYPOINT_BUSINESS_GROUP_ID":"anypoint.businessGroupId",
    "ANYPOINT_BUSINESS_GROUP":   "anypoint.businessGroup",
    "CONNECTED_APP_GRANT_TYPE":  "connected.app.grantType",
    "RTF_TARGET":                "rtf.target",
    "RTF_PROVIDER":              "rtf.provider",
    "RTF_APPLICATION_NAME":      "rtf.applicationName",
    "RTF_REPLICAS":              "rtf.replicas",
    "MULE_ENV":                  "mule.env",
    "SKIP_TESTS":                "skipTests",
    "MULE_VERSION":              "muleVersion",
    "RELEASE_CHANNEL":           "releaseChannel",
    "JAVA_VERSION":              "javaVersion",
    "DEPLOYMENT_TIMEOUT":        "deploymentTimeout",
    "SKIP_DEPLOYMENT":           "skip",
    "SKIP_DEPLOYMENT_VERIFICATION": "skipDeploymentVerification",
    # deploymentSettings parameters
    "ENFORCE_DEPLOYING_REPLICAS_ACROSS_NODES": "rtf.enforceDeployingReplicasAcrossNodes",
    "UPDATE_STRATEGY":           "updateStrategy",
    "CLUSTERED":                 "clustered",
    "RTF_CPU_RESERVED":          "rtf.cpuReserved",
    "RTF_CPU_LIMIT":             "rtf.cpuLimit",
    "RTF_MEMORY_RESERVED":       "rtf.memoryReserved",
    "RTF_MEMORY_LIMIT":          "rtf.memoryLimit",
    "HTTP_INBOUND_PUBLIC_URL":   "http.inbound.publicUrl",
    "PERSISTENT_OBJECT_STORE":   "persistentObjectStore",
    "JVM_ARGS":                  "rtf.jvm.args",
    "GENERATE_DEFAULT_PUBLIC_URL":"generateDefaultPublicUrl",
    "DISABLE_AM_LOG_FORWARDING": "disableAmLogForwarding",
    "AUTOSCALING_ENABLED":       "autoscaling.enabled",
    "AUTOSCALING_MIN_REPLICAS":  "autoscaling.minReplicas",
    "AUTOSCALING_MAX_REPLICAS":  "autoscaling.maxReplicas",
    # New Relic logging
    "AWS_SECRET_ENV":            "aws.secret.env",
    "NR_LOGS_PARTITION":         "nr_logs_partition",
    "NR_DATA_PARTITION":         "nr_data_partition",
    "NR_DATA_ENCODING":          "nr_data_encoding",
    "NR_URL":                    "nr_url",
    "LOG_LEVEL":                 "logLevel",
}

# Secret keys — shell var references, masked via GitHub workflow masking
SECRET_ARGS = [
    ("connected.app.clientId",     "CONNECTED_APP_CLIENT_ID"),
    ("connected.app.clientSecret", "CONNECTED_APP_CLIENT_SECRET"),
]
OPTIONAL_SECRET_ARGS = [
    ("mule.key", "MULE_KEY"),
]


def load_properties(path):
    """Parse a key=value properties file, skipping comments and blanks."""
    props = {}
    p = pathlib.Path(path) if path else None
    if not p or not p.is_file():
        return props
    for line in p.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("["):
            continue
        key, _, value = line.partition("=")
        key, value = key.strip(), value.strip()
        if key:
            props[key] = value
    return props


def apply_overrides(props):
    """Override properties with non-empty caller env vars. Returns set of overridden keys."""
    overridden = set()
    for env_var, prop_key in OVERRIDES.items():
        val = os.environ.get(env_var, "").strip()
        if val:
            props[prop_key] = val
            overridden.add(prop_key)
    return overridden


def build_mvn_command(props, pom_file_path):
    """Build the mvn deploy command from the final properties dict."""
    args = [f"mvn package -f {pom_file_path}/pom.xml"]

    for key, value in props.items():
        args.append(f"-D{key}={value}")

    for prop_key, env_var in SECRET_ARGS:
        args.append(f"-D{prop_key}=${env_var}")

    for prop_key, env_var in OPTIONAL_SECRET_ARGS:
        if os.environ.get(env_var, ""):
            args.append(f"-D{prop_key}=${env_var}")

    return " ".join(args)


def mask_secrets():
    """Register secret values with GitHub's ::add-mask:: workflow command."""
    for _, env_var in SECRET_ARGS + OPTIONAL_SECRET_ARGS:
        val = os.environ.get(env_var, "").strip()
        if val:
            print(f"::add-mask::{val}")


def print_config_summary(props_file, file_props, overridden_keys, final_props, mvn_command):
    """Print a debug-friendly summary showing where each value comes from."""
    sep = "═" * 60
    print(f"\n{sep}")
    print("🚀 RTF DEPLOY CONFIGURATION SUMMARY")
    print(sep)
    print(f"  Properties file: {props_file}")
    print(f"  Properties loaded: {len(file_props)}")
    print(f"  Action overrides applied: {len(overridden_keys)}")

    # Show all final values with their source
    print(f"\n{'─' * 60}")
    print(f"  {'PROPERTY':<45} {'SOURCE'}")
    print(f"{'─' * 60}")
    for key in sorted(final_props):
        source = "← action input" if key in overridden_keys else "  properties file"
        print(f"  {key:<45} {source}")
        print(f"    = {final_props[key]}")

    # Secrets (just show which ones are present)
    print(f"\n{'─' * 60}")
    print("  SECRETS")
    print(f"{'─' * 60}")
    for prop_key, env_var in SECRET_ARGS + OPTIONAL_SECRET_ARGS:
        present = "✓" if os.environ.get(env_var, "").strip() else "✗"
        print(f"  {present} {prop_key}")

    print(f"\n{'─' * 60}")
    print("  MAVEN COMMAND")
    print(f"{'─' * 60}")
    print(f"  {mvn_command}")
    print(sep)


def main():
    pom_file_path = os.environ.get("POM_FILE_PATH", "")
    props_file = os.environ.get("DEPLOY_PROPERTIES_FILE", "")

    # Validate pom.xml
    pom = pathlib.Path(pom_file_path) / "pom.xml"
    if not pom.is_file():
        print(f"::error::pom.xml not found at {pom}", file=sys.stderr)
        sys.exit(1)

    # Load properties file
    file_props = load_properties(props_file)
    if not file_props:
        print("::error::No properties loaded — check DEPLOY_PROPERTIES_FILE", file=sys.stderr)
        sys.exit(1)

    # Apply caller overrides on top of file values
    final_props = dict(file_props)
    overridden_keys = apply_overrides(final_props)

    # Mask secrets before any output that could contain them
    mask_secrets()

    # Build maven command
    mvn_command = build_mvn_command(final_props, pom_file_path)

    # Print debug summary
    print_config_summary(props_file, file_props, overridden_keys, final_props, mvn_command)

    # Write to GITHUB_OUTPUT
    output_file = os.environ.get("GITHUB_OUTPUT")
    if output_file:
        with open(output_file, "a") as out:
            out.write(f"mvn_command={mvn_command}\n")
    else:
        print("⚠️  GITHUB_OUTPUT not set — printing to stdout only", file=sys.stderr)
        print(f"\nmvn_command={mvn_command}")


if __name__ == "__main__":
    main()











