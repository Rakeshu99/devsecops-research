#!/bin/bash
# OPA policy evaluation script — Open-Source Stack, Tool 5 of 5
# Evaluates a GitHub Actions workflow file against a custom Rego security policy
# that detects untrusted 'github' context data used directly in shell run: steps.
#
# Usage: ./run-opa-evaluation.sh <path-to-workflow.yml>
# Example: ./run-opa-evaluation.sh ~/WebGoat/.github/workflows/release.yml

WORKFLOW_FILE="${1:-.github/workflows/release.yml}"
JSON_OUTPUT="/tmp/workflow-converted.json"

echo "=== Converting workflow YAML to JSON ==="
python3 -c "import yaml, json; print(json.dumps(yaml.safe_load(open('$WORKFLOW_FILE'))))" > "$JSON_OUTPUT"

echo "=== Running OPA policy evaluation ==="
opa eval --data github-actions-security.rego --input "$JSON_OUTPUT" "data.githubactions.deny" --format pretty > opa-evaluation-results.txt

cat opa-evaluation-results.txt

echo "=== Evaluation complete. Results saved to opa-evaluation-results.txt ==="
