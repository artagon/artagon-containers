#!/usr/bin/env python3
"""Generate vulnerability scan attestation JSON from Trivy and Grype results."""

import json
import os
import sys
from datetime import datetime, timezone


def count_trivy(data):
    """Count vulnerabilities by severity from Trivy JSON output."""
    counts = {}
    for result in data.get("Results", []):
        for vuln in result.get("Vulnerabilities") or []:
            sev = vuln.get("Severity", "UNKNOWN")
            counts[sev] = counts.get(sev, 0) + 1
    return counts


def count_grype(data):
    """Count vulnerabilities by severity from Grype JSON output."""
    counts = {}
    for match in data.get("matches", []):
        sev = match.get("vulnerability", {}).get("severity", "Unknown")
        counts[sev] = counts.get(sev, 0) + 1
    return counts


def main():
    target = os.environ["TARGET"]
    trivy_path = os.environ.get("TRIVY_PATH", f"attestations/trivy-{target}.json")
    grype_path = os.environ.get("GRYPE_PATH", f"scan/grype-{target}.json")
    output_path = os.environ.get("OUTPUT_PATH", f"attestations/scan-{target}.json")

    # Handle different directory structures (build-push vs release)
    if not os.path.exists(trivy_path):
        trivy_path = f"scan/trivy-{target}.json"
    if not os.path.exists(grype_path):
        grype_path = f"attestations/grype-{target}.json"

    with open(trivy_path, "r", encoding="utf-8") as fh:
        trivy_data = json.load(fh)
    with open(grype_path, "r", encoding="utf-8") as fh:
        grype_data = json.load(fh)

    payload = {
        "target": target,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "trivy": {
            "version": os.environ["TRIVY_VERSION"],
            "exit_code": int(os.environ["TRIVY_EXIT"]),
            "counts": count_trivy(trivy_data),
        },
        "grype": {
            "version": os.environ["GRYPE_VERSION"],
            "exit_code": int(os.environ["GRYPE_EXIT"]),
            "counts": count_grype(grype_data),
        },
    }

    with open(output_path, "w", encoding="utf-8") as fh:
        json.dump(payload, fh, indent=2)

    print(f"Generated attestation: {output_path}")


if __name__ == "__main__":
    main()
