# Trivy Scan Results — Open-Source Stack, Tool 2 of 5

**Date:** 22 June 2026
**Tool:** Trivy v0.71.2
**Target:** `webgoat/webgoat` Docker image (the running container's source image)
**Command:**
```bash
trivy image webgoat/webgoat --severity CRITICAL,HIGH --timeout 15m
```

---

## Scan Summary

| Target | Type | Vulnerabilities Found |
|---|---|---|
| webgoat/webgoat (Ubuntu 24.04 base OS) | OS packages | 11 (HIGH: 11, CRITICAL: 0) |
| home/webgoat/webgoat.jar | Java application dependencies | 51 (HIGH: 39, CRITICAL: 12) |
| **Total** | | **62** |

---

## Setup and Operational Issues Encountered

**1. Official install script failed.** The documented Trivy install script (`install.sh` from the official GitHub repo) failed with a DNS resolution error on `get.trivy.dev`. Resolved by switching to Trivy's official APT repository instead. This is a real-world setup friction point relevant to Metric 3 (Setup Complexity) — the documented "quick install" path was not reliable in this environment.

**2. Default timeout (5 minutes) was insufficient.** Initial scan attempt failed with `context deadline exceeded`. Resolved by setting `--timeout 15m`. Relevant to Metric 4 (Pipeline Overhead) — default tool configuration was not adequate for a moderately complex Java application image.

**3. First-run database downloads added significant one-time overhead.** Two separate vulnerability databases were downloaded on first run:
   - Vulnerability DB: 97.13 MiB
   - Java DB (for JAR dependency scanning): 883.57 MiB
   Combined download time was approximately 9 minutes on this connection. Both databases are cached locally afterward (Java DB cached for 3 days), so subsequent scans will not repeat this cost. This is a one-time setup cost worth noting separately from per-scan overhead.

**4. Secret scanning significantly slows large file analysis.** Trivy's secret scanner flagged `webgoat.jar` (142 MB) as too large for efficient secret scanning and recommended `--skip-files` or `--scanners vuln` to disable it. Vulnerability and secret scanning were run together in this scan; a faster comparative run could isolate `--scanners vuln` only.

---

## Most Significant Findings (CRITICAL severity)

| Library | CVE | Issue | Fixed Version |
|---|---|---|---|
| com.thoughtworks.xstream:xstream 1.4.5 | CVE-2013-7285 | Remote code execution via insecure XML deserialization | 1.4.7 / 1.4.11 |
| org.apache.tomcat.embed:tomcat-embed-core 10.1.36 | CVE-2026-41293 | HTTP/2 request headers not validated | 9.0.118 / 10.1.55 / 11.0.22 |
| org.springframework.security:spring-security-core 6.4.3 | CVE-2025-41232 | Authorization bypass for method security annotations | 6.4.6 |
| org.springframework.security:spring-security-web | CVE-2026-22732 | Security policy bypass and information disclosure | 6.5.9 / 7.0.4 |
| org.thymeleaf:thymeleaf 3.1.2.RELEASE | CVE-2026-40477 | Server-side template injection via security bypass | 3.1.4.RELEASE |

---

## Comparison With Semgrep (Tool 1) — Important Analytical Distinction

| Aspect | Semgrep | Trivy |
|---|---|---|
| What it scans | Source code (developer-written logic) | Container image (OS packages + dependency manifests) |
| What it finds | Code-level security anti-patterns (SQL injection construction, insecure crypto calls, unvalidated redirects) | Known CVEs in third-party libraries and OS packages |
| Findings count | 20 | 62 |
| Overlap with Semgrep findings | None — entirely different vulnerability classes | None |

**Key methodological point:** raw finding counts between tools are not directly comparable, because each tool targets a different layer of the software supply chain. Semgrep and Trivy results are complementary rather than competing — a realistic SME pipeline would benefit from both rather than choosing one over the other. This should be reflected in the final analysis rather than treating "more findings" as inherently "better detection."

---

## Relevance to Research Metrics

| Metric | Data Point From This Scan |
|---|---|
| 1. Detection capability | 62 dependency/OS-level vulnerabilities detected, including 12 CRITICAL severity issues in outdated Java libraries |
| 3. Setup complexity | Official install method failed (DNS issue); APT fallback required. Documented as a real friction point. |
| 4. Pipeline overhead | ~9 minutes one-time database download (cached after); actual scan execution itself was fast once databases were present |
| 5. Cost | Free, fully open-source, no account required (unlike Semgrep Pro tier) |
| 6. SME suitability | No license required; but default timeout and DNS reliability issues suggest some initial configuration tuning needed for production CI/CD use |

---

**CI verification:** These findings were independently reproduced through the automated GitHub Actions pipeline (`opensource-stack.yml`) on 7 July 2026, following a change from filesystem scanning (`trivy fs .`) to image scanning (`trivy image webgoat/webgoat`) to avoid a Maven Central rate-limit error encountered when the pipeline attempted live dependency resolution in CI. See `docs/implementation-log.md` (7 July entry) for full details.
