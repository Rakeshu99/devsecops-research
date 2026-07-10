# Comparing Open-Source and Cloud-Native AI/ML Security Tools as a Pre-Pipeline Gate in DevSecOps CI/CD Pipelines: A Study of SME Suitability

MSc Research Project — TU Dublin, Computing with DevOps
**Student:** Rakesh Uday Kumar (A00047386)
**Supervisor:** Dr. Shivani Jaswal
**Module:** RESH-H6002-53441-TU437-PT-202520

---

## Research Question

Can a lightweight AI/ML pre-pipeline security gate be deployed in a DevSecOps CI/CD pipeline in a way that measurably improves security outcomes for SMEs, without adding significant complexity or operational overhead?

---

## Motivation

The 2020 SolarWinds SUNBURST breach demonstrated that rule-based security tools failed to detect malicious code injected directly into a CI/CD pipeline. Current AI/ML-enhanced security frameworks are designed for enterprise environments and remain largely inaccessible to small and medium enterprises (SMEs) due to cost and infrastructure requirements. This project builds and evaluates two pre-pipeline security gates — one using open-source tools, one using cloud-native services — to determine which approach is more suitable for SMEs.

---

## What Is Included

- An open-source security stack (Semgrep, Trivy, Trufflehog, Falco, OPA) integrated as a pre-pipeline gate — **all five tools complete, verified both manually and through automated CI/CD**
- An Azure cloud-native security stack (Defender for DevOps, Defender for Cloud, GitHub Advanced Security, Microsoft Sentinel, Azure Policy) integrated as an equivalent pre-pipeline gate — **in progress**
- A deliberately vulnerable test application (OWASP WebGoat) with introduced OWASP Top 10 CI/CD Security Risks
- GitHub Actions pipeline configurations for both stacks, plus a baseline (no security tooling) control pipeline
- A documented evaluation across six metrics: detection capability, false positive rate, setup complexity, pipeline overhead, cost, and SME suitability

---

## Methodology

Design Science Research (Hevner et al., 2004), structured across four phases:

1. **Requirements definition** — derived from literature review (CA1)
2. **Open-source stack construction and testing**
3. **Azure cloud-native stack construction and testing**
4. **Comparative evaluation and analysis**

DSR was selected because this project builds and evaluates a technical artefact, rather than only observing existing systems (case study) or requiring organisational participation (action research).

**Note on cloud vendor:** the original CA2 proposal specified AWS (CodeGuru, GuardDuty, Security Hub) as the cloud-native comparison stack. This was revised to Azure, confirmed with the supervisor by email on 22 June 2026, due to AWS free-tier trial windows (15–30 days per service) being incompatible with the project's iterative testing timeline, versus the longer window offered by an Azure for Students account.

---

## Test Environment

- **Application:** OWASP WebGoat — deliberately vulnerable Java application
- **Pipeline:** GitHub Actions
- **Threats:** Deliberately introduced, based on the OWASP Top 10 CI/CD Security Risks
- Both stacks tested against an identical environment and identical introduced vulnerabilities for fair comparison

---

## Evaluation Metrics

1. **Detection capability** — vulnerabilities correctly identified per stack
2. **False positive rate** — legitimate commits incorrectly flagged
3. **Setup complexity** — time and steps required to configure each stack
4. **Pipeline overhead** — additional time added per pipeline run
5. **Cost** — total cost of running each stack across the experimental phase
6. **SME suitability** — composite assessment across all criteria for small teams with limited budget and no dedicated security engineer

---

## Project Map

- `docs/` — implementation log, architecture notes, academic justifications
- `stacks/opensource/` — configuration files and reusable scripts for Semgrep, Trivy, Trufflehog, Falco, OPA
- `stacks/azure/` — configuration files for the Azure-native stack
- `.github/workflows/` — GitHub Actions pipeline definitions (baseline, open-source, Azure)
- `metrics/collection/` — scripts used to collect and structure results
- `metrics/results/` — raw tool output, screenshots, comparison tables
- `vulnerabilities/` — documentation of deliberately introduced vulnerabilities and their purpose

### Results So Far — Open-Source Stack Complete

| Tool | Findings | Full Results |
|---|---|---|
| Semgrep | 20 (code-level: SQL injection, path traversal, insecure crypto, CI/CD shell injection) | `metrics/results/semgrep-results.md` |
| Trivy | 62 (dependency/OS-level: outdated XStream, Tomcat, Spring Security, Thymeleaf) | `metrics/results/trivy-results.md` |
| Trufflehog | 2 in WebGoat (non-operational JWTs); 2 of 4 (50%) detected in Azure-relevant controlled test — Azure Storage connection string and DB password missed, GitHub token and Slack webhook detected | `metrics/results/trufflehog-results.md` |
| Falco | Successfully detected shell spawned inside running container, with full process/container context | `metrics/results/falco-results.md` |
| OPA | Correctly flagged the same CI/CD shell injection risk found independently by Semgrep (true positive); zero false positives on a clean control input (true negative) | `metrics/results/opa-results.md` |

**Notable cross-validation finding:** Semgrep (static code analysis) and OPA (policy-as-code evaluation) independently identified the same shell injection vulnerability in WebGoat's `.github/workflows/release.yml`, using entirely different detection mechanisms. This corroboration strengthens confidence that the finding represents a genuine issue rather than a tool-specific false positive.

**CI/CD pipeline verification:** All findings above were first established through direct manual tool execution, then independently reproduced through the automated GitHub Actions pipeline (`opensource-stack.yml`). Two configuration issues were identified and resolved during this verification (missing submodule checkout, and scan-target mismatches for Semgrep and Trivy) — see `docs/implementation-log.md` for the full account.

### Results So Far — Azure Stack In Progress

| Component | Findings | Notes |
|---|---|---|
| CodeQL / GitHub Advanced Security | 71 (3 Critical, 52 High, 16 Medium) | See `metrics/results/screenshots/08-azure-ghas/` |
| Dependabot | Not populated — documented GitHub limitation | GitHub's dependency graph does not scan manifests inside git submodules; see `docs/implementation-log.md`, 7 July entry |
| Defender for Cloud | 75 findings (3 Critical, 52 High, 20 Medium) | Substantially the same underlying data as CodeQL, aggregated with a small number of additional scanner findings (Checkov, Bandit, ESLint) — not a fully independent detection engine, see note below |
| Microsoft Sentinel | Not started | |
| Azure Policy | Not started | |

**Notable finding — Defender for Cloud is a dashboard layer, not independent detection:** Defender for Cloud's "DevOps security" findings (75 total) closely match CodeQL's own results (71 total) on Critical and High counts exactly (3 and 52 respectively), with a small additional set of Medium findings. This confirms Defender for Cloud aggregates CodeQL's scan results into its dashboard, rather than running a fully separate detection engine. This is a relevant SME suitability finding: Defender for Cloud's primary value in this context is centralised visibility and reporting, not additional independent detection coverage.

**Setup friction encountered:** the Defender for Cloud GitHub connector initially failed to provision due to a system-level Azure Policy (`sys.regionrestriction`) on the Azure for Students subscription, restricting deployment to a specific set of regions (Switzerland North, Sweden Central, Poland Central, Canada Central, Spain Central) not including the initially selected North Europe / West Europe. Resolved by redeploying to Sweden Central. See `docs/implementation-log.md` for the full troubleshooting account — this is a citable Metric 3 (Setup Complexity) finding.

---

## Project Timeline

| Phase | Dates | Focus |
|---|---|---|
| 1 | 2–15 June | Environment setup, open-source stack build |
| 2 | 16–30 June | Open-source stack testing and results collection |
| 3 | 1–20 July | Azure stack testing and results collection |
| 4 | 21–31 July | Comparative analysis |
| 5 | 1–31 August | Write-up and submission |

---

## Status

| Phase | Status |
|---|---|
| Environment setup (Ubuntu VM, Docker, WebGoat deployment) | ✅ Complete |
| Open-source stack — Semgrep (static code analysis) | ✅ Complete — 20 findings against WebGoat source code, verified manually and in CI |
| Open-source stack — Trivy (container/dependency scanning) | ✅ Complete — 62 findings against WebGoat Docker image, verified manually and in CI |
| Open-source stack — Trufflehog (secret detection) | ✅ Complete — 2 findings in WebGoat (non-operational), verified manually and in CI; 2 of 4 (50%) detected in Azure-relevant controlled test |
| Open-source stack — Falco (runtime anomaly detection) | ✅ Complete — successfully detected shell spawned in container, with full forensic context |
| Open-source stack — OPA (policy enforcement) | ✅ Complete — cross-validated Semgrep's finding; zero false positives on control test |
| **Open-source stack overall** | **✅ ALL 5 TOOLS COMPLETE, VERIFIED MANUALLY AND IN CI** |
| Baseline GitHub Actions pipeline (no security tools) | ✅ Complete — confirmed running in 11 seconds (control condition baseline) |
| Open-source stack GitHub Actions pipeline (CI automation) | ✅ Complete — all four applicable tools (Semgrep, Trivy, Trufflehog, OPA) verified scanning real WebGoat content in automated CI |
| Azure — CodeQL / GitHub Advanced Security | ✅ Complete — 71 findings, verified |
| Azure — Dependabot | 🔶 Documented as a limitation — submodule dependency scanning not supported natively, corroborated against WebGoat's upstream repo |
| Azure — Defender for Cloud | ✅ Complete — GitHub connector live, 75 findings confirmed, region-restriction issue resolved (Sweden Central) |
| Azure — Microsoft Sentinel | ⬜ Not started |
| Azure — Azure Policy | ⬜ Not started |
| Azure stack GitHub Actions pipeline (CI automation, timing) | ⬜ Not started |
| Comparative analysis | ⬜ Not started |

See `docs/implementation-log.md` for full setup details and `metrics/results/` for tool-by-tool findings and analysis.

**Next step:** Set up Microsoft Sentinel (Log Analytics workspace, then Sentinel onboarding), then Azure Policy (built-in Security Benchmark initiative assignment), then build the Azure stack GitHub Actions pipeline for equivalent timing comparison. Note: pipeline timing figures for the open-source stack (baseline ~12s, stack ~27s) were captured before the CI submodule fix and require re-measurement under corrected conditions before use in the comparative analysis.
