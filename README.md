# Comparing Open-Source and Cloud-Native AI/ML Security Tools as a Pre-Pipeline Gate in DevSecOps CI/CD Pipelines: A Study of SME Suitability

MSc Research Project — TU Dublin, Computing with DevOps
**Name:** Rakesh Uday Kumar (A00047386)
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

- An open-source security stack (Semgrep, Trivy, Trufflehog, Falco, OPA) integrated as a pre-pipeline gate
- An Azure cloud-native security stack (Defender for DevOps, Defender for Cloud, GitHub Advanced Security, Microsoft Sentinel, Azure Policy) integrated as an equivalent pre-pipeline gate
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
- `stacks/opensource/` — configuration files for Semgrep, Trivy, Trufflehog, Falco, OPA
- `stacks/azure/` — configuration files for the Azure-native stack
- `.github/workflows/` — GitHub Actions pipeline definitions (baseline, open-source, Azure)
- `metrics/collection/` — scripts used to collect and structure results
- `metrics/results/` — raw tool output, screenshots, comparison tables
- `vulnerabilities/` — documentation of deliberately introduced vulnerabilities and their purpose

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

Environment setup complete: Ubuntu VM provisioned, Docker installed, OWASP WebGoat deployed and verified accessible. See `docs/implementation-log.md` for full setup details and evidence.

**Next step:** Integration of Semgrep as the first open-source tool, with results captured against WebGoat's source code.

