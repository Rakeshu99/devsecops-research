# Semgrep Scan Results — Open-Source Stack, Tool 1 of 5

**Date:** 22 June 2026
**Tool:** Semgrep CLI v1.167.0
**Ruleset:** `p/owasp-top-ten` (Community tier, 544 rules total, 160 applicable to WebGoat's file types)
**Target:** WebGoat source code (github.com/WebGoat/WebGoat, cloned locally)
**Command:**
```bash
semgrep --config=p/owasp-top-ten --json --output=semgrep-results.json .
semgrep --config=p/owasp-top-ten .
```

---

## Scan Summary

| Metric | Value |
|---|---|
| Files scanned | 974 (git-tracked only) |
| Languages covered | Java (316 files), JavaScript (81), HTML (69), YAML (9), JSON (9), Bash (3), Dockerfile (1) |
| Rules executed | 160 |
| **Findings** | **20 (20 marked Blocking)** |
| Scan duration | 1 minute 18 seconds |
| Parsed lines | ~99.9% |
| Files skipped | 2 (>1.0MB), 102 (matched `.semgrepignore`) |

---

## Findings by Vulnerability Category

| Category | Count | OWASP Top 10 Mapping |
|---|---|---|
| SQL Injection (manually-constructed / formatted SQL strings) | 9 | A03:2021 — Injection |
| Path Traversal | 2 | A01:2021 — Broken Access Control |
| Insecure Cryptography (MD5 usage) | 1 | A02:2021 — Cryptographic Failures |
| Server-Side Request Forgery (SSRF) | 1 | A10:2021 — SSRF |
| Open Redirect (unvalidated) | 1 | A01:2021 — Broken Access Control |
| Session / Trust Boundary Violation | 1 | A04:2021 — Insecure Design |
| CI/CD Pipeline Shell Injection (GitHub Actions) | 1 | OWASP CI/CD Top 10 — CICD-SEC-4 |
| Spring Actuator Misconfiguration (exposed endpoints) | 1 | A05:2021 — Security Misconfiguration |
| Insecure HTTP Link | 1 | A02:2021 — Cryptographic Failures |
| **Total** | **20** | |

---

## Notable Finding — CI/CD-Specific Risk

`.github/workflows/release.yml` — `yaml.github-actions.security.run-shell-injection`

Untrusted `github` context data (`${{ github.ref_name }}`) used directly in a `run:` shell step without sanitisation via an intermediate environment variable. This is directly relevant to the research motivation (SolarWinds-style pipeline compromise via untrusted input reaching CI/CD execution context).

---

## Limitations Observed

1. **Free-tier rule coverage:** Semgrep reported 1,803 Pro-tier rules were not applied (requires `semgrep login` / paid account). The 544 Community rules applied represent the realistic free-tier capability an SME would have access to without additional cost — directly relevant to Metric 5 (Cost) and Metric 6 (SME Suitability).
2. **Scan timeouts on large third-party JS libraries:** `ace.js`, `jquery-ui-1.10.4.js`, and `wysihtml5-0.3.0.js` each triggered 3 timeout errors and were excluded from full rule coverage after threshold was hit. This is a relevant operational consideration for setup complexity (Metric 3) — large vendored JS dependencies may need timeout tuning (`--timeout-threshold`) in real-world SME deployments.

---

## Relevance to Research Metrics

| Metric | Data Point From This Scan |
|---|---|
| 1. Detection capability | 20 vulnerabilities detected, correctly identifying WebGoat's deliberately introduced weaknesses (9 SQL injection findings against an app whose stated purpose includes SQL injection training) |
| 4. Pipeline overhead | 78 seconds for 974 files — baseline figure for comparison against Azure-native equivalent |
| 5. Cost | Free (Community tier); Pro tier (1,803 additional rules) requires paid account |
| 6. SME suitability | No infrastructure required beyond `pip install`; runs locally or in CI within ~80 seconds — low barrier to entry |
