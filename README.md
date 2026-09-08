# Comparing Open-Source and Cloud-Native AI/ML Security Tools as a Pre-Pipeline Gate in DevSecOps CI/CD Pipelines: A Study of SME Suitability

MSc Research Project — TU Dublin, Computing with DevOps
Student: Rakesh Uday Kumar (A00047386)
Supervisor: Dr. Shivani Jaswal
Module: RESH-H6002-53441-TU437-PT-202520

**Status: Complete. Submitted 31 August 2026.**
**Full thesis:** [`docs/A00047386_FinalThesis_Submission.pdf`](docs/A00047386_FinalThesis_Submission.pdf)

## Research Question

Can a lightweight AI/ML pre-pipeline security gate be deployed in a DevSecOps CI/CD pipeline in a way that measurably improves security outcomes for SMEs, without adding significant complexity or operational overhead?

## Motivation

The 2020 SolarWinds SUNBURST breach demonstrated that rule-based security tools failed to detect malicious code injected directly into a CI/CD pipeline. Critically, SUNBURST was engineered to evade behavioural and anomaly-based detection as well as signature-based tools — through a dormancy period designed to defeat sandbox analysis, command-and-control traffic disguised as legitimate telemetry, and code delivered under the organisation's own trusted signing certificate. This precedent motivates a question this study investigates empirically rather than assumes: does AI/ML-augmented cloud-native tooling (e.g., Microsoft Sentinel's behavioural correlation engine) meaningfully reduce this class of risk for SMEs, or does its added complexity outweigh a benefit that has not been demonstrated under conditions representative of real supply-chain compromise? Current AI/ML-enhanced security frameworks are largely designed for enterprise environments and remain inaccessible to small and medium enterprises due to cost and infrastructure requirements. This project builds and evaluates two pre-pipeline security gates — one using open-source tools, one using cloud-native services — to determine which approach is more suitable for SMEs.

## What Is Included

- An open-source security stack (Semgrep, Trivy, Trufflehog, Falco, OPA) integrated as a pre-pipeline gate — all five tools complete, verified both manually and through automated CI/CD
- An Azure cloud-native security stack (Defender for DevOps, Defender for Cloud, GitHub Advanced Security, Microsoft Sentinel, Azure Policy) integrated as an equivalent pre-pipeline gate — all components complete and verified, including one documented platform limitation (Dependabot)
- A deliberately vulnerable test application (OWASP WebGoat) with introduced OWASP Top 10 CI/CD Security Risks
- GitHub Actions pipeline configurations for both stacks, plus a baseline (no security tooling) control pipeline
- A documented evaluation across six metrics: detection capability, false positive rate, setup complexity, pipeline overhead, cost, and SME suitability

## Methodology

Design Science Research (Hevner et al., 2004), structured across four phases:

1. Requirements definition — derived from literature review (CA1)
2. Open-source stack construction and testing
3. Azure cloud-native stack construction and testing
4. Comparative evaluation and analysis

DSR was selected because this project builds and evaluates a technical artefact, rather than only observing existing systems (case study) or requiring organisational participation (action research).

**Note on cloud vendor:** the original CA2 proposal specified AWS (CodeGuru, GuardDuty, Security Hub) as the cloud-native comparison stack. This was revised to Azure, confirmed with the supervisor by email on 22 June 2026, due to AWS free-tier trial windows (15–30 days per service) being incompatible with the project's iterative testing timeline, versus the longer window offered by an Azure for Students account.

## Test Environment

- **Application:** OWASP WebGoat — deliberately vulnerable Java application
- **Pipeline:** GitHub Actions
- **Threats:** Deliberately introduced, based on the OWASP Top 10 CI/CD Security Risks
- Both stacks tested against an identical environment and identical introduced vulnerabilities for fair comparison

## Evaluation Metrics

- **Detection capability** — vulnerabilities correctly identified per stack
- **False positive rate** — legitimate commits incorrectly flagged
- **Setup complexity** — time and steps required to configure each stack
- **Pipeline overhead** — additional time added per pipeline run
- **Cost** — total cost of running each stack across the experimental phase
- **SME suitability** — composite assessment across all criteria for small teams with limited budget and no dedicated security engineer

## Project Timeline

Based on the actual commit history of this repository.

| Phase | Dates | Focus |
|---|---|---|
| 1 | 22 June 2026 | Environment setup — Ubuntu VM, Docker, WebGoat deployment, initial repo structure |
| 2 | 22–30 June 2026 | Open-source stack build and testing — Semgrep and Trivy (22–23 June), Trufflehog and Falco (28–29 June), OPA and both GitHub Actions pipelines (30 June) |
| 3 | 5–13 July 2026 | Azure stack build and testing — CodeQL/GHAS (5 July), Dependabot limitation documented (7–8 July), Defender for Cloud (10 July), Sentinel (10–13 July), Azure Policy and azure-stack.yml pipeline with same-session timing comparison (13 July) |
| 4 | 13 July–2 August 2026 | Comparative analysis — literature reference set finalised (14 July), OPA policy set expanded to three risk classes (16 July), pipeline timing re-measured across three interleaved rounds and comparative-analysis.md added (20 July), final two cross-portal inconsistency findings documented (2 August) |
| 5 | 4–31 August 2026 | Thesis write-up and final submission |

## Status

| Phase | Status |
|---|---|
| Environment setup (Ubuntu VM, Docker, WebGoat deployment) | ✅ Complete — 22 June 2026 |
| Open-source stack — Semgrep (static code analysis) | ✅ Complete — 20 findings against WebGoat source code, verified manually and in CI — 22 June 2026 |
| Open-source stack — Trivy (container/dependency scanning) | ✅ Complete — 62 findings against WebGoat Docker image, verified manually and in CI — 22–23 June 2026 |
| Open-source stack — Trufflehog (secret detection) | ✅ Complete — 2 findings in WebGoat (non-operational), verified manually and in CI; 2 of 4 (50%) detected in Azure-relevant controlled test — 28–29 June 2026 |
| Open-source stack — Falco (runtime anomaly detection) | ✅ Complete — successfully detected shell spawned in container, with full forensic context — 29 June 2026 |
| Open-source stack — OPA (policy enforcement) | ✅ Complete — cross-validated Semgrep's finding; zero false positives on control test; later expanded to three risk classes with six ground-truth cases — 30 June 2026, expanded 16 July |
| Open-source stack overall | ✅ All 5 tools complete, verified manually and in CI |
| Baseline GitHub Actions pipeline (no security tools) | ✅ Complete — mean 16.3s across 3 interleaved trials — 30 June 2026, timing re-measured 20 July |
| Open-source stack GitHub Actions pipeline (CI automation) | ✅ Complete — all four applicable tools (Semgrep, Trivy, Trufflehog, OPA) verified scanning real WebGoat content in automated CI — 30 June, CI target fixes 8 July |
| Azure — CodeQL / GitHub Advanced Security | ✅ Complete — 71 findings, verified — 5 July 2026 |
| Azure — Dependabot | 🔶 Documented as a limitation — submodule dependency scanning not supported natively, corroborated against WebGoat's upstream repo — 7–8 July 2026 |
| Azure — Defender for Cloud | ✅ Complete — GitHub connector live, 75 findings confirmed, region-restriction issue resolved (Sweden Central) — 10 July 2026 |
| Azure — Microsoft Sentinel | ✅ Complete — confirmed working as designed (posture Recommendations do not generate Incidents; verified 11 July, documented in repo 13 July 2026) |
| Azure — Azure Policy | ✅ Complete — ASC Default + benchmark v2 assigned and evaluating; multi-metric compliance finding documented (verified 11 July, sixth compliance metric added 2 August 2026) |
| Azure stack GitHub Actions pipeline (CI automation, timing) | ✅ Complete — azure-stack.yml built, same-session timing comparison captured 13 July, later confirmed via three-round interleaved re-measurement 20 July 2026 |
| Comparative analysis (all six metrics) | ✅ Complete — full six-metric comparison, hypothesis testing (H1/H2), and SME-suitability synthesis in Chapter 5 of the thesis — comparative-analysis.md added 20 July, final findings 2 August 2026 |
| Thesis write-up | ✅ Complete — all chapters, references, and appendices finalised — August 2026 |
| Final submission | ✅ Submitted 31 August 2026 |

See `docs/implementation-log.md` for full setup details and `metrics/results/` for tool-by-tool findings and analysis.

## Supervisor Engagement

Weekly status calls with Dr. Shivani Jaswal (Tuesdays, throughout the project) tracked progress alongside the commit history above, with draft reports submitted directly by email at key milestones:

- **5 August 2026, 10:40 PM** — draft report submitted (marked High Importance), covering the project up to that point.
- **24 August 2026, 12:05 AM** — completed draft report submitted, reflecting the finished thesis structure ahead of final formatting and submission.

## Project Map

- `docs/` — implementation log, architecture notes, academic justifications, full thesis PDF
- `stacks/opensource/` — configuration files and reusable scripts for Semgrep, Trivy, Trufflehog, Falco, OPA
- `stacks/azure/` — configuration files for the Azure-native stack
- `.github/workflows/` — GitHub Actions pipeline definitions (baseline, open-source, Azure)
- `metrics/collection/` — scripts used to collect and structure results
- `metrics/results/` — raw tool output, screenshots, comparison tables
- `vulnerabilities/` — documentation of deliberately introduced vulnerabilities and their purpose
- `app/` — OWASP WebGoat test application (git submodule)
- `test-secrets-controlled/` — controlled secret-detection test fixtures used for Trufflehog false-positive evaluation

## Open-Source Stack — Results

| Tool | Findings | Full Results |
|---|---|---|
| Semgrep | 20 (code-level: SQL injection, path traversal, insecure crypto, CI/CD shell injection) | `metrics/results/semgrep-results.md` |
| Trivy | 62 (dependency/OS-level: outdated XStream, Tomcat, Spring Security, Thymeleaf) | `metrics/results/trivy-results.md` |
| Trufflehog | 2 in WebGoat (non-operational JWTs); 2 of 4 (50%) detected in Azure-relevant controlled test — Azure Storage connection string and DB password missed, GitHub token and Slack webhook detected | `metrics/results/trufflehog-results.md` |
| Falco | Successfully detected shell spawned inside running container, with full process/container context | `metrics/results/falco-results.md` |
| OPA | Correctly flagged the same CI/CD shell injection risk found independently by Semgrep (true positive); zero false positives on a clean control input (true negative) | `metrics/results/opa-results.md` |

**Notable cross-validation finding:** Semgrep (static code analysis) and OPA (policy-as-code evaluation) independently identified the same shell injection vulnerability in WebGoat's `.github/workflows/release.yml`, using entirely different detection mechanisms. This corroboration strengthens confidence that the finding represents a genuine issue rather than a tool-specific false positive.

**CI/CD pipeline verification:** all findings above were first established through direct manual tool execution, then independently reproduced through the automated GitHub Actions pipeline (`opensource-stack.yml`). Two configuration issues were identified and resolved during this verification (missing submodule checkout, and scan-target mismatches for Semgrep and Trivy) — see `docs/implementation-log.md` for the full account.

## Azure Stack — Results

| Component | Findings | Notes |
|---|---|---|
| CodeQL / GitHub Advanced Security | 71 (3 Critical, 52 High, 16 Medium) | See `metrics/results/screenshots/08-azure-ghas/` |
| Dependabot | Not populated — documented GitHub limitation | GitHub's dependency graph does not scan manifests inside git submodules; see `docs/implementation-log.md`, 7 July entry |
| Defender for Cloud | 75 findings (3 Critical, 52 High, 20 Medium) | Substantially the same underlying data as CodeQL, aggregated with a small number of additional scanner findings — not a fully independent detection engine, see note below |
| Microsoft Sentinel | Confirmed working as designed | Workspace and trial active (10 Jul–8 Aug 2026); tenant Cloud Security onboarding completed 10 Jul; incidents/alerts remain 0 by design (see note below) |
| Azure Policy | Compliance confirmed, multi-metric finding documented | "ASC Default" (226 policies) plus "Microsoft cloud security benchmark v2" (730 policies) both actively evaluating; six distinct, non-reconciled compliance metrics observed for the same evaluation |

**Notable finding — Defender for Cloud is a dashboard layer, not independent detection:** Defender for Cloud's "DevOps security" findings (75 total) closely match CodeQL's own results (71 total) on Critical and High counts exactly (3 and 52 respectively), with a small additional set of Medium findings. This confirms Defender for Cloud aggregates CodeQL's scan results into its dashboard, rather than running a fully separate detection engine. This is a relevant SME suitability finding: Defender for Cloud's primary value in this context is centralised visibility and reporting, not additional independent detection coverage.

**Setup friction encountered:** the Defender for Cloud GitHub connector initially failed to provision due to a system-level Azure Policy (`sys.regionrestriction`) on the Azure for Students subscription, restricting deployment to a specific set of regions not including the initially selected North Europe / West Europe. Resolved by redeploying to Sweden Central. See `docs/implementation-log.md` for the full troubleshooting account — this is a citable Setup Complexity finding.

**Notable finding — Sentinel/Defender for Cloud "zero incidents" is expected behaviour, not a defect:** despite Defender for Cloud generating 75 confirmed findings, zero incidents or alerts ever appeared in Sentinel, even after completing tenant Cloud Security onboarding. This is correct, by-design behaviour: the 75 findings are posture/configuration Recommendations, which feed the Secure Score and posture dashboards, not Security Alerts, which are the only findings that generate Incidents. A discrepancy was also observed between the Defender portal's Data Connectors view (1 connector) and the native Azure Sentinel blade's Data Connectors view for the same workspace (7 connectors) — evidence of an ongoing platform-transition inconsistency between the two UIs Microsoft is mid-way through unifying. This is one of five independently confirmed instances of the same cross-portal/cross-view inconsistency pattern found across this project (see `docs/comparative-analysis.md`), including a case where the identical Cloud Security Overview page shows contradictory secure scores (31.2% vs 86.9%) depending solely on an environment filter toggle.

**Notable finding — Azure Policy compliance is reported through multiple, non-reconciled metrics:** an "ASC Default" initiative (226 policies) was found already assigned to the subscription automatically by Defender for Cloud, with no manual configuration. The full "Microsoft cloud security benchmark v2" initiative (730 policies) was additionally assigned for comprehensive coverage. Checking compliance results surfaced six distinct metrics for the same evaluation, with materially different values (ranging from 25% to ~89% depending on which metric is read). This is a relevant SME suitability finding: Azure does not present one authoritative "compliance %," and a team without deep platform familiarity could easily cite the wrong metric or misinterpret partial compliance as comprehensive.

## Pipeline Overhead — Timing Comparison

Measured across three interleaved rounds (baseline, then open-source, then Azure, repeated three times) to rule out runner or network noise skewing any single result.

| Round | Baseline | Open-source | Azure (CodeQL) |
|---|---|---|---|
| 1 | 18s | 1m 4s (64s) | 2m 34s (154s) |
| 2 | 16s | 1m 7s (67s) | 2m 40s (160s) |
| 3 | 15s | 1m 6s (66s) | 2m 39s (159s) |
| **Mean** | **16.3s** | **65.7s** | **157.7s** |
| Range | 15–18s | 64–67s | 154–160s |

**Azure stack scope note:** `azure-stack.yml` runs CodeQL only. Dependabot, Defender for Cloud, Sentinel, and Azure Policy are deliberately excluded — none execute as an inline CI step; all evaluate asynchronously at the platform level. This is itself a Pipeline Overhead finding: most of the Azure stack adds zero measurable per-run overhead by architecture, unlike the open-source stack where every tool runs inline on every push. The gap that does exist is explained by CodeQL's `build-mode: manual`, which requires compiling WebGoat via Maven before analysis can run — a real depth-vs-speed trade-off, not incidental inefficiency. Full breakdown in `docs/implementation-log.md`.

## Summary of Findings

Full results, methodology, and discussion are in the thesis (Chapters 4–7). In brief:

- CodeQL found substantially more code-level findings than Semgrep (71 vs. 20) — a genuine structural-detection advantage, at the cost of a mandatory build step and longer pipeline time.
- The open-source stack showed lower setup complexity (2 vs. 6 documented friction points) and lower pipeline overhead than the Azure stack's CodeQL component.
- Microsoft Sentinel's AI/ML behavioural correlation engine was never exercised under adversarial conditions within this study's scope — this is treated throughout as **untested, not disproven**, not as a negative finding about AI/ML security tooling in general.
- Overall, the open-source stack is favoured on 5 of 6 evaluation metrics; CodeQL's added detection depth is the one clear advantage for the Azure stack.

## Reproducing This Study

1. Clone the repository (`git submodule update --init` for the WebGoat submodule).
2. Pipeline definitions are in `.github/workflows/` (baseline, open-source, Azure).
3. OPA Rego policies and tool configuration are in `stacks/opensource/` and `stacks/azure/` (see Appendix A of the thesis for the full OPA policy listing, Appendix B for the baseline workflow).
4. Azure components (Defender for Cloud, Sentinel, Azure Policy) require an Azure subscription with GitHub connector access configured; see Chapter 4 of the thesis for setup details.

## Citation

Kumar, R.U. (2026) *Comparing Open-Source and Cloud-Native AI/ML Security Tools as a Pre-Pipeline Gate in DevSecOps CI/CD Pipelines: A Study of SME Suitability*. MSc thesis, Technological University Dublin.
