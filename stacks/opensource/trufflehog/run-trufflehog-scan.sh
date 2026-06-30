#!/bin/bash
# Trufflehog scan script — Open-Source Stack, Tool 3 of 5
# Scans the WebGoat source code for hardcoded secrets and credentials
#
# Usage: ./run-trufflehog-scan.sh
# Run from the WebGoat source directory: ~/WebGoat
#
# Notes:
# - Use --no-update flag to avoid auto-updater permission error when binary
#   is owned by root (/usr/local/bin/trufflehog) but run as non-root user
# - Output is directed to /tmp/ to avoid self-scan contamination
#   (Trufflehog will re-scan its own output file if written inside the target dir)

echo "=== Running Trufflehog secret detection scan against WebGoat source ==="

trufflehog filesystem . --no-update > /tmp/trufflehog-findings-readable.txt 2>&1

echo "=== Scan complete. Results saved to /tmp/trufflehog-findings-readable.txt ==="
cat /tmp/trufflehog-findings-readable.txt

echo ""
echo "=== Running controlled detection test (Azure + GitHub token patterns) ==="
echo "Note: Run test-secrets-controlled/ test separately if needed"
echo "See metrics/results/trufflehog-controlled-test.txt for controlled test results"
