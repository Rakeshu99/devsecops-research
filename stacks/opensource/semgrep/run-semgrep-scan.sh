#!/bin/bash
# Semgrep scan script — Open-Source Stack, Tool 1 of 5
# Run from the WebGoat source directory: ~/WebGoat
#
# Usage: ./run-semgrep-scan.sh

echo "=== Running Semgrep OWASP Top Ten scan against WebGoat ==="

# JSON output for machine-readable results / automated comparison later
semgrep --config=p/owasp-top-ten --json --output=semgrep-results.json .

# Human-readable output for report evidence
semgrep --config=p/owasp-top-ten . > semgrep-findings-readable.txt 2>&1

echo "=== Scan complete. Results saved to semgrep-results.json and semgrep-findings-readable.txt ==="
