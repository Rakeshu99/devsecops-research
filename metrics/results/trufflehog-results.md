# Trufflehog Scan Results — Open-Source Stack, Tool 3 of 5

**Date:** 28 June 2026
**Tool:** Trufflehog v3.95.6
**Target 1:** WebGoat source code (full repository scan)
**Target 2:** Controlled test file with deliberately injected fake secrets (supplementary test)

---

## Part 1 — WebGoat Source Code Scan

**Command:**
```bash
trufflehog filesystem . --no-update
```

### Scan Summary

| Metric | Value |
|---|---|
| Chunks scanned | 12,362 |
| Data scanned | 151.6 MB |
| **Secrets found** | **2 (both unverified)** |
| Verified secrets | 0 |
| Scan duration | 41 seconds |

### Findings

Both findings were JWT tokens embedded in WebGoat's own JWT lesson documentation (`src/main/resources/lessons/jwt/html/JWT.html`, `src/main/resources/lessons/jwt/documentation/JWT_libraries.adoc`). These are intentional teaching examples within WebGoat's curriculum content, not leaked operational credentials. Trufflehog correctly marked both as "unverified" — meaning it attempted live verification and could not confirm them as active, working credentials.

### Interpretation

WebGoat's deliberate vulnerabilities are concentrated in code logic flaws (SQL injection, path traversal, insecure cryptography — as found by Semgrep) and outdated dependencies (as found by Trivy), rather than hardcoded operational secrets. This is a property of the test application, not a Trufflehog limitation, and is an important methodological note: **WebGoat alone does not provide a sufficient test case for evaluating secret-detection capability.** A supplementary controlled test was therefore conducted (Part 2 below) to generate a genuine detection-capability data point.

### Setup Note

An initial scan run produced a misleading duplicate result, caused by the scan's own output file (`trufflehog-findings-readable.txt`) being written into the directory being scanned, which Trufflehog then re-scanned as part of the same run. Resolved by directing output outside the scanned directory (`/tmp/`). This is a minor but real operational consideration relevant to Metric 3 (Setup Complexity) — output destination must be excluded from scan scope.

---

## Part 2 — Controlled Detection Capability Test

**Objective:** WebGoat did not contain realistic hardcoded secrets, so a controlled test file was created with four deliberately injected fake credentials of varying type and structure, to directly measure Trufflehog's detection capability.

**Test file contents (`test-secrets-controlled/fake-credentials.env`):**
- An Azure Client Secret (fake)
- An Azure Storage Connection String (fake)
- A generic database password (fake)
- A GitHub personal access token (fake, using AWS/GitHub's own published example-format conventions)

**Command:**
```bash
trufflehog filesystem test-secrets-controlled/ --no-update
```

### Result

| Secret Type Injected | Detected? |
|---|---|
| GitHub Token | ✅ Detected (unverified) |
| Azure Client Secret | ❌ Not detected |
| Azure Storage Connection String | ❌ Not detected |
| Generic Database Password | ❌ Not detected |

**Detection rate: 1 of 4 (25%)**

### Analysis — Significant Finding for This Research

This result is directly relevant to the project's core comparison, particularly given the project's cloud-native stack is Azure-based:

1. **Strong detector coverage for well-known platforms.** Trufflehog correctly identified the GitHub token using its specific structured format (`ghp_` prefix + character pattern) and even returned a credential-rotation guide link — indicating mature, well-maintained detection logic for major platforms.
2. **No detection of Azure-specific credential formats in this test.** Neither the Azure Client Secret nor the Azure Storage Connection String were flagged, despite both following realistic Azure credential structures. This suggests Trufflehog's out-of-the-box detector set has a gap for Azure-specific secret types — directly relevant to evaluating open-source tool suitability for organisations operating in an Azure environment.
3. **No detection of unstructured secrets (plain passwords).** This is an expected and inherent limitation of pattern-based secret detection generally, not specific to Trufflehog — credentials without a fixed, recognisable format cannot be reliably caught by signature-based detectors.

This is a legitimate limitation to report rather than a tool failure to hide. It directly informs Metric 1 (Detection Capability) and Metric 6 (SME Suitability) — an SME using Azure as their primary cloud provider would need to verify whether their specific Azure secret types are covered by Trufflehog's detector library, or supplement with Azure-native secret scanning (Defender for DevOps / GitHub Advanced Security) as part of a layered approach.

---

## Relevance to Research Metrics

| Metric | Data Point |
|---|---|
| 1. Detection capability | 2 findings in WebGoat (non-operational JWTs); 1 of 4 (25%) detected in controlled test — strong on GitHub-format secrets, gap identified on Azure-specific formats |
| 3. Setup complexity | Install required `sudo` due to binary write permissions; auto-update check required `--no-update` flag to avoid runtime error |
| 4. Pipeline overhead | 41 seconds for full WebGoat repository scan (151.6 MB) |
| 5. Cost | Free, fully open source |
| 6. SME suitability | Detection gap on Azure-specific secret types is a meaningful consideration for SMEs standardising on Azure — may require supplementary Azure-native secret scanning |
