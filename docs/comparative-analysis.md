# Comparative Analysis — Open-Source vs Azure Stack

This document is the single source of truth for the six-metric comparison.
All figures below are cross-checked against README.md, docs/implementation-log.md,
and raw output in metrics/results/ as of this entry's date. The thesis
Comparative Analysis chapter is drawn from this document, not the reverse.

## Metric 1 — Detection Capability

| | Open-source stack | Azure stack |
|---|---|---|
| Code-level SAST | Semgrep: 20 findings | CodeQL: 71 findings (3 Critical, 52 High, 16 Medium) |
| Dependency/container scanning | Trivy: 62 findings | Dependabot: 0 (submodule scanning limitation — see note) |
| Secret detection | Trufflehog: 2 in WebGoat; 2/4 (50%) in controlled test | — (no direct Azure equivalent tested) |
| Runtime detection | Falco: shell-spawn detected, full forensic context | — (Sentinel's behavioural layer not exercised — see Future Work) |
| Policy enforcement | OPA: 3 policies, 6/6 true-positive/negative cases confirmed | Azure Policy: 226+730 policies evaluating (see Metric 3) |
| Aggregated posture | — | Defender for Cloud: 75 findings, confirmed to substantially mirror CodeQL (same Critical/High counts, +4 Medium from bundled scanners) |

**Key finding:** raw counts are not directly comparable across stacks — Defender for Cloud's 75 is not independent of CodeQL's 71, and Dependabot's 0 is a platform limitation, not an absence of vulnerabilities (Trivy found 62 in the same codebase).

## Metric 2 — False Positive Rate

Three OPA policies, each with a true-positive and true-negative case, tested against WebGoat's real workflow files:

| Policy | Risk class | True Positive | True Negative |
|---|---|---|---|
| Shell injection | CICD-SEC-1: Insufficient Flow Control | Confirmed (1 finding) | Confirmed |
| Action pinning | CICD-SEC-3: Dependency Chain Abuse | Confirmed (7 findings) | Confirmed |
| Secret logging | CICD-SEC-6: Insufficient Credential Hygiene | Confirmed | Confirmed (0 findings) |

Six ground-truth data points across three distinct risk classes, up from the original two. Two real bugs were caught and fixed while building this evidence base — see `docs/implementation-log.md`, 20 July entry — itself relevant evidence for the Setup Complexity metric.

## Metric 3 — Setup Complexity

| Friction point | Stack | Root cause | Diagnosis difficulty |
|---|---|---|---|
| CI submodule bug | Open-source | Missing `submodules: recursive` on 4 checkout steps | Medium — found via cross-checking CI artifacts vs manual results |
| OPA CI job targeting wrong file | Open-source | Job evaluated its own workflow YAML instead of WebGoat's | High — silent, no error, undiscovered until unrelated work exposed it |
| Region restriction (`sys.regionrestriction`) | Azure | Subscription policy not reflected in connector UI | High — required raw Activity Log JSON inspection |
| Sentinel zero-incidents | Azure | Tenant Cloud Security onboarding never triggered, separate from connector/gallery | High — multi-step diagnostic path |
| Dependabot submodule gap | Azure | Platform limitation, no warning surfaced | Medium — required corroboration against upstream repo |
| Cross-portal inconsistency (4 instances) | Azure | Different Azure/Defender portals report different numbers for the same environment | Medium — requires knowing to check more than one view |

**Score: 2 friction points in open-source stack, 4 in Azure stack.**

## Metric 4 — Pipeline Overhead

Interleaved comparison, 3 rounds (Baseline → Open-source → Azure, repeated), 16 July 2026, controlling for runner/network variance:

| Round | Baseline | Open-source | Azure (CodeQL) |
|---|---|---|---|
| 1 | 18s | 1m 4s (64s) | 2m 34s (154s) |
| 2 | 16s | 1m 7s (67s) | 2m 40s (160s) |
| 3 | 15s | 1m 6s (66s) | 2m 39s (159s) |
| **Mean** | **16.3s** | **65.7s** | **157.7s** |
| **Range** | 15–18s | 64–67s | 154–160s |

Variance was low across all three (3–6s spread), confirming the original single-run figures (13 July) were representative, not outliers.

**Key finding:** CodeQL's `build-mode: manual` requires compiling WebGoat via Maven — a real depth-vs-speed trade-off. Dependabot, Defender for Cloud, Sentinel, and Azure Policy add **zero** inline pipeline overhead, since all four evaluate asynchronously at the platform level rather than as CI steps.

## Metric 5 — Cost

| | Open-source stack | Azure stack |
|---|---|---|
| Licensing | Free / open-source, no cost at any usage level tested | CodeQL + Azure Policy free; Defender for Cloud + Sentinel on 30–31 day trials, per-resource/per-GB billing after |
| This project's exposure | £0 | $0.00 confirmed via Azure's own cost estimate (Pay-as-you-go tier, 0 GB ingested, 31/90-day usage charts show "No data") |
| Trial expiry | N/A | 9–10 August 2026 (calculated from 10 July start + 30–31 day window; not directly surfaced anywhere in the Azure portal UI) |

**Key finding:** true SME cost comparison requires sustained post-trial pricing data, which this study's timeframe does not capture — noted as a limitation.

## Metric 6 — SME Suitability (synthesis)

| Dimension | Favours |
|---|---|
| Ongoing cost | Open-source |
| Detection transparency (traceable to specific rule/pattern) | Open-source |
| Initial setup friction | Azure (4 friction points vs 2, several harder to diagnose) |
| Ongoing interpretive complexity | Open-source (Azure: cross-portal inconsistency observed 4 separate times, 5 non-reconciled compliance metrics, Recommendations-vs-Alerts confusion) |
| Detection depth (semantic vs pattern-based) | Azure (CodeQL's data-flow analysis) |
| Pipeline speed | Open-source |

**Overall finding:** for an SME without a dedicated security engineer, the open-source stack's transparency and zero ongoing cost outweigh the Azure stack's deeper semantic analysis in CodeQL specifically. The recurring cross-portal inconsistency pattern (4 independent instances across Sentinel, Azure Policy, and Defender for Cloud) is itself a genuine SME-suitability finding: Azure's tooling is powerful but does not present a single, trustworthy view of security state, which matters more for a team without the expertise to know which portal to check.

---

**Verification note:** last cross-checked against README.md and docs/implementation-log.md on 20 July 2026.
