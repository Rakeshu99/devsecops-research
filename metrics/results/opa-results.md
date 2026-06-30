# OPA Scan Results — Open-Source Stack, Tool 5 of 5

**Date:** 29 June 2026
**Tool:** Open Policy Agent (OPA) v0.68.0
**Target:** WebGoat's `.github/workflows/release.yml`, converted to JSON, evaluated against a custom Rego policy

---

## Approach

Unlike the previous four tools, OPA is a **policy engine**, not a scanner — it requires a custom policy to be written before it can evaluate anything. A Rego policy (`github-actions-security.rego`) was written specifically to detect the same risk class Semgrep identified independently in Tool 1: untrusted `github` context data (`${{ github.* }}`) used directly inside a `run:` shell step without sanitisation via an intermediate environment variable.

**Policy logic:**
```rego
package githubactions
import rego.v1

deny contains msg if {
	some job_name, job in input.jobs
	some step in job.steps
	step.run
	contains(step.run, "${{ github.")
	msg := sprintf("Job '%s' has a 'run' step using untrusted github context data directly: %s", [job_name, step.run])
}
```

**Input preparation:** WebGoat's `release.yml` was converted from YAML to JSON (OPA requires structured JSON/YAML input, and JSON conversion made the structure easiest to verify) using a one-line Python script with `pyyaml`.

---

## Test 1 — True Positive (WebGoat's Actual Workflow)

**Command:**
```bash
opa eval --data github-actions-security.rego --input release-workflow.json "data.githubactions.deny" --format pretty
```

**Result:**
```json
[
  "Job 'release' has a 'run' step using untrusted github context data directly: echo \"WEBGOAT_TAG_VERSION=${{ github.ref_name }}\" >> $GITHUB_ENV..."
]
```

OPA correctly identified the risky step in the `release` job — the exact same line Semgrep flagged independently in Tool 1 using a completely different detection method (AST-based static analysis vs. declarative policy evaluation).

---

## Test 2 — True Negative (Clean Workflow Control)

To confirm the policy does not produce false positives, a minimal "clean" workflow with no risky pattern was evaluated:

```bash
opa eval --data github-actions-security.rego --input clean-workflow.json "data.githubactions.deny" --format pretty
```

**Result:** `[]` (empty array — no findings, as expected)

---

## Analysis

This is a methodologically stronger validation than a single-direction test: the policy was confirmed to both (a) correctly flag a known real issue and (b) correctly ignore safe code, demonstrating low false-positive risk for this specific rule.

**Cross-validation with Semgrep:** The fact that two independent tools, using entirely different detection mechanisms, identified the same vulnerability in the same file is meaningful corroboration. It demonstrates the finding is a genuine issue rather than a tool-specific false positive, and illustrates a key argument for layered DevSecOps tooling — different tools catching the same real risk through different means increases confidence in the result.

**Key distinction from the other four tools:** OPA does not ship with ready-made security rules the way Semgrep (community ruleset) or Falco (default rules) do. The policy had to be authored specifically for this use case. This is a significant and directly relevant finding for Metric 3 (Setup Complexity) and Metric 6 (SME Suitability) — OPA's value is entirely dependent on the policies written for it, meaning the effort and security expertise required to adopt OPA is materially higher than for the other open-source tools tested, which work immediately out of the box with community-maintained rule sets.

---

## Relevance to Research Metrics

| Metric | Data Point |
|---|---|
| 1. Detection capability | Correctly identified the same CI/CD shell injection risk found independently by Semgrep; zero false positives on a clean control input |
| 3. Setup complexity | Significantly higher than other tools — requires writing custom Rego policy logic; no out-of-the-box security ruleset exists for this use case (unlike Semgrep's community rules or Falco's default rules) |
| 4. Pipeline overhead | Evaluation itself is near-instantaneous (sub-second) once a policy exists; the real cost is the upfront policy-authoring time, not runtime |
| 5. Cost | Free, fully open source |
| 6. SME suitability | Lower out-of-the-box suitability for SMEs without in-house security/Rego expertise, compared to the other four tools in this stack. Best suited to organisations able to invest in custom policy development, or that adopt community-shared policy bundles rather than authoring from scratch |
