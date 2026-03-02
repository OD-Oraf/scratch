"""
Build a Maven deploy command from a deploy-config properties file.

The properties file contains all the -D flags for the mvn deploy command.
The action caller can override any property by passing it as an action input
(org/env-specific values that should be common across all applications).

Secrets are injected as shell variable references so they never appear in
GITHUB_OUTPUT — the executing step provides them via env vars at runtime.
"""

import os
import pathlib
import sys


# ── Caller overrides: env var → properties-file key ──────────────────────
# When a caller passes an action input, it arrives here as an env var.
# If the env var has a value, it overrides the matching key from the file.
OVERRIDES = {
    # Anypoint Platform
    "ANYPOINT_URI":              "anypoint.uri",
    "ANYPOINT_ENVIRONMENT":      "anypoint.environment",
    "ANYPOINT_BUSINESS_GROUP_ID":"anypoint.businessGroupId",
    "CONNECTED_APP_GRANT_TYPE":  "connected.app.grantType",
    # RTF top-level
    "RTF_TARGET":                "rtf.target",
    "RTF_PROVIDER":              "rtf.provider",
    "RTF_APPLICATION_NAME":      "rtf.applicationName",
    "RTF_REPLICAS":              "rtf.replicas",
    "RTF_CPU_RESERVED":          "rtf.cpuReserved",
    "RTF_CPU_MAX":               "rtf.cpuMax",
    "RTF_MEMORY_RESERVED":       "rtf.memoryReserved",
    "RTF_MEMORY_MAX":            "rtf.memoryMax",
    # Mule runtime
    "MULE_ENV":                  "mule.env",
    "SKIP_TESTS":                "skipTests",
    # deploymentSettings
    "ENFORCE_DEPLOYING_REPLICAS_ACROSS_NODES": "rtf.enforceDeployingReplicasAcrossNodes",
    "UPDATE_STRATEGY":           "updateStrategy",
    "CLUSTERED":                 "clustered",
    "HTTP_INBOUND_PUBLIC_URL":   "http.inbound.publicUrl",
    "PERSISTENT_OBJECT_STORE":   "persistentObjectStore",
    "JVM_ARGS":                  "rtf.jvm.args",
    "GENERATE_DEFAULT_PUBLIC_URL":"generateDefaultPublicUrl",
    "DISABLE_AM_LOG_FORWARDING": "disableAmLogForwarding",
    "AUTOSCALING_ENABLED":       "autoscaling.enabled",
    "AUTOSCALING_MIN_REPLICAS":  "autoscaling.minReplicas",
    "AUTOSCALING_MAX_REPLICAS":  "autoscaling.maxReplicas",
    "DEPLOYMENT_TIMEOUT":        "deploymentTimeout",
    "MULE_VERSION":              "muleVersion",
    "RELEASE_CHANNEL":           "releaseChannel",
    "JAVA_VERSION":              "javaVersion",
}

# Secret keys — referenced as $SHELL_VARS in the command, masked via GitHub workflow masking
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
    print(f"📄 Loading properties from {path}")
    for line in p.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("["):
            continue
        key, _, value = line.partition("=")
        key, value = key.strip(), value.strip()
        if key:
            props[key] = value
            print(f"  {key}={value}")
    return props


def apply_overrides(props):
    """Override properties with non-empty values from caller env vars."""
    for env_var, prop_key in OVERRIDES.items():
        val = os.environ.get(env_var, "").strip()
        if val:
            print(f"  override: {prop_key}={val}")
            props[prop_key] = val
    return props


def build_mvn_command(props, pom_file_path):
    """Build the mvn deploy command from the final properties dict.
        Using package instead of deploy as a dry-run. No need to do actual deployment
    """
    args = [
        f"mvn package -f {pom_file_path}/pom.xml"
        # "-DmuleDeploy",
    ]

    # All properties from the file (with overrides applied) become -D flags
    for key, value in props.items():
        args.append(f"-D{key}={value}")

    # Secrets as shell variable references (never stored in GITHUB_OUTPUT)
    for prop_key, env_var in SECRET_ARGS:
        args.append(f"-D{prop_key}=${env_var}")

    for prop_key, env_var in OPTIONAL_SECRET_ARGS:
        if os.environ.get(env_var, ""):
            args.append(f"-D{prop_key}=${env_var}")

    return " ".join(args)


def mask_secrets():
    """Register secret values with GitHub's workflow masking via ::add-mask::."""
    for _, env_var in SECRET_ARGS + OPTIONAL_SECRET_ARGS:
        val = os.environ.get(env_var, "").strip()
        if val:
            print(f"::add-mask::{val}")


def print_summary(props, mvn_command):
    """Print a human-readable deploy summary."""
    print("")
    print("═══════════════════════════════════════════════════════")
    print("🚀 DEPLOYING TO RTF")
    print("═══════════════════════════════════════════════════════")
    print(f"  Application: {props.get('rtf.applicationName', 'N/A')}")
    print(f"  Environment: {props.get('anypoint.environment', 'N/A')}")
    print(f"  Target:      {props.get('rtf.target', 'N/A')}")
    print(f"  Replicas:    {props.get('rtf.replicas', 'N/A')}")
    print(f"  CPU:         {props.get('rtf.cpuReserved', 'N/A')} / {props.get('rtf.cpuMax', 'N/A')}")
    print(f"  Memory:      {props.get('rtf.memoryReserved', 'N/A')} / {props.get('rtf.memoryMax', 'N/A')}")
    print("")
    print("Maven command:")
    print(f"  {mvn_command}")
    print("")


def main():
    # Get POM and properties files
    pom_file_path = os.environ.get("POM_FILE_PATH", "")
    props_file = os.environ.get("DEPLOY_PROPERTIES_FILE", "")

    # Validate pom.xml to make sure it exists
    pom = pathlib.Path(pom_file_path) / "pom.xml"
    if not pom.is_file():
        print(f"::error::pom.xml not found at {pom}", file=sys.stderr)
        sys.exit(1)
    print(f"✓ Found pom.xml at {pom}")

    # Load properties file
    props = load_properties(props_file)
    if not props:
        print("::error::No properties loaded — check DEPLOY_PROPERTIES_FILE", file=sys.stderr)
        sys.exit(1)

    # Override values defined in caller workflow
    print("\n📝 Applying caller overrides:")
    apply_overrides(props)

    # Mask secret values in GitHub Actions logs
    mask_secrets()

    # Create maven arguments from properties file and overrides
    mvn_command = build_mvn_command(props, pom_file_path)

    # Print summary
    print_summary(props, mvn_command)

    # Write to GitHub output variable to be used by subsequent steps
    output_file = os.environ.get("GITHUB_OUTPUT")
    if output_file:
        with open(output_file, "a") as out:
            out.write(f"mvn_command={mvn_command}\n")
    else:
        print("⚠️  GITHUB_OUTPUT not set — printing to stdout only", file=sys.stderr)
        print(f"\nmvn_command={mvn_command}")


if __name__ == "__main__":
    main()
