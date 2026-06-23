#!/bin/bash
# Trivy scan script — Open-Source Stack, Tool 2 of 5
# Scans the WebGoat Docker image for OS and dependency CVEs
#
# Usage: ./run-trivy-scan.sh

echo "=== Running Trivy scan against webgoat/webgoat image ==="

# Note: --timeout 15m required — default 5m timeout is insufficient for this image
# Note: first run downloads ~980MB of vulnerability databases (cached afterward)
trivy image webgoat/webgoat --severity CRITICAL,HIGH --timeout 15m --format table > trivy-findings-readable.txt 2>&1

# JSON output for machine-readable results / automated comparison later
trivy image webgoat/webgoat --severity CRITICAL,HIGH --timeout 15m --format json --output trivy-results.json

echo "=== Scan complete. Results saved to trivy-results.json and trivy-findings-readable.txt ==="
