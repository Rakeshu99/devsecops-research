# Literature Review — Reference Notes

## Reference set

| Citation | Year | Relevance |
|---|---|---|
| Myrbakken, H. & Colomo-Palacios, R. *DevSecOps: A Multivocal Literature Review.* International Conference on Software Process Improvement and Capability Determination (SPICE 2017), Springer, pp. 17–29. | 2017 | Foundational — one of the earliest academic treatments of DevSecOps, establishing its definition, characteristics, benefits, and adoption challenges. Directly cited within Rajapakse et al. (2022) as an early grounding study, giving this literature review a traceable lineage rather than an isolated historical citation. |
| Charoenwet, W., Thongtanunam, P., Pham, V.T., & Treude, C. *An Empirical Study of Static Analysis Tools for Secure Code Review.* ISSTA 2024, pp. 691–703. | 2024 | Evaluates five SAST tools including CodeQL directly against real vulnerability-contributing commits rather than synthetic test cases. Supports this study's discussion of WebGoat's realistic-vulnerability limitation relative to purpose-built benchmarks, and gives a direct external comparison point for this study's own CodeQL results. |
| Ccallo-Luque, M. & Quispe-Quispe, A. *Adoption and Adaptation of CI/CD Practices in Very Small Software Development Entities: A Systematic Literature Review.* arXiv:2410.00623. | 2024 | Closest existing match to this study's SME/VSE framing. Confirms very small entities lack validated CI/CD adoption guidance, at the level of a practice review rather than empirical tool comparison. |
| Rajapakse, R.N., Zahedi, M., Babar, M.A., & Shen, H. *Challenges and solutions when adopting DevSecOps: A systematic review.* Information and Software Technology, 141, 106700. | 2022 | Systematic review of 54 peer-reviewed studies identifying 21 adoption challenges and 31 solutions across People, Practices, Tools, and Infrastructure themes. Establishes tool-related challenges as the most frequently reported category, directly supporting this study's setup-complexity findings. |
| Cheenepalli, J., Hastings, J.D., Ahmed, K.M., & Fenner, C. *Advancing DevSecOps in SMEs: Challenges and Best Practices for Secure CI/CD Pipelines.* ISDFS 2025, pp. 1–6. | 2025 | Base paper. SME DevSecOps adoption survey. |
| Nair, A., Nicolazzo, S., Nocera, A., Rafidha Rehiman, K.A., & Vinod, P. *SoK: Zero Trust as a Strategy to Address DevSecOps Challenges.* EuroS&PW 2025, pp. 546–554. | 2025 | Base paper. Zero Trust in DevSecOps. |
| Mahimalur, R.K., Amgothu, S., Reddy, B.R.T., & Gadde, S.S. *Modern Cloud Security and Automation: A DevSecOps Approach Leveraging AI/ML and Containerization.* ICECA 2025, pp. 305–312. | 2025 | Base paper. AI/ML-enhanced CI/CD pipeline implementation. |
| Wienczkowski, M. *Adaptive and AI-Augmented Security Testing: A Systematic Survey of Program Analysis, Feedback-Driven Testing, and Hybrid Learning-Based Approaches.* Mississippi State University, arXiv:2604.27000. | 2026 | Systematic survey of 55 peer-reviewed studies. Identifies a persistent gap between structural program analysis and adaptive, feedback-driven detection — supports this study's framing of AI/ML-augmented tooling as an open empirical question rather than an assumed improvement. |

The reviewed literature spans 2017–2026 and traces a lineage from the field's
earliest academic definition through to current systematic reviews and
empirical studies, combining foundational, methodological, and current
perspectives rather than resting on a single publication year.

---

## Positioning against the existing literature

Myrbakken and Colomo-Palacios (2017) establish DevSecOps as a field-defining
concept but rely on grey literature rather than empirical measurement, a
limitation Rajapakse et al. (2022) themselves note when situating their own
systematic review. Rajapakse et al. (2022) advance this considerably,
identifying tool-related challenges as the most frequently reported adoption
barrier across 54 studies, but their review remains at the level of
practitioner-reported challenges rather than direct empirical tool execution.
Ccallo-Luque and Quispe-Quispe (2024) confirm that Very Small Entities lack
validated CI/CD adoption guidance, again at the level of practice-cataloguing
rather than empirical comparison. Charoenwet et al. (2024) move closer to
this study's approach by empirically testing SAST tools, including CodeQL,
against real vulnerability data, but their scope is limited to static
analysis alone and does not extend to secret detection, runtime monitoring,
policy enforcement, or cloud-native governance tooling. Wienczkowski (2026)
surveys fifty-five studies and identifies a persistent fragmentation between
rich structural program analysis and adaptive, feedback-driven detection — a
conceptual gap this study investigates empirically by measuring whether
Microsoft Sentinel's behavioural correlation layer delivers detection value
beyond what rule-based tooling already provides, rather than surveying claims
about it.

None of the reviewed literature executes an open-source and a cloud-native
AI/ML-augmented stack side-by-side against a shared test artefact, integrated
into functioning CI/CD pipelines, and measured across setup complexity,
pipeline overhead, and SME cost simultaneously. This is the specific
empirical gap this study addresses.

---

## Motivation

The 2020 SolarWinds SUNBURST breach demonstrated that rule-based security
tools failed to detect malicious code injected directly into a CI/CD
pipeline. SUNBURST was engineered to evade behavioural and anomaly-based
detection as well as signature-based tools, through a dormancy period
designed to defeat sandbox analysis, command-and-control traffic disguised as
legitimate telemetry, and code delivered under the organisation's own trusted
signing certificate. This precedent motivates a question investigated
empirically rather than assumed here: does AI/ML-augmented cloud-native
tooling meaningfully reduce this class of risk for SMEs, or does its added
complexity outweigh a benefit that has not been demonstrated under conditions
representative of real supply-chain compromise. Current AI/ML-enhanced
security frameworks are largely designed for enterprise environments and
remain inaccessible to small and medium enterprises due to cost and
infrastructure requirements. This project builds and evaluates two
pre-pipeline security gates, one using open-source tools and one using
cloud-native services, to determine which approach is genuinely suitable for
SMEs.

---

## Future work

**Behavioural detection under adversarial conditions.** This study measured
Microsoft Sentinel's posture-reporting and alert-model behaviour against a
static test application, and did not generate live attack traffic. Its
behavioural correlation engine was therefore never exercised under conditions
representative of the evasion techniques SUNBURST demonstrated. A follow-up
study incorporating a live attack-simulation phase would test whether this
layer provides detection value beyond the static posture findings measured
here.

**Ground-truth benchmark replication.** This study used OWASP WebGoat, a
realistic teaching application, rather than OWASP Benchmark, a purpose-built
test suite with labelled ground-truth vulnerabilities used in comparable
academic SAST evaluations, including Charoenwet et al. (2024). WebGoat's
realistic vulnerabilities do not support precise recall or precision scoring
in the way Benchmark's labelled cases do. Replicating this comparison against
OWASP Benchmark would allow quantified detection-accuracy scoring alongside
the qualitative and setup-complexity findings reported here.

**Interpretive complexity as a distinct cost dimension.** This study found
that Azure's compliance and alerting model imposes real interpretive burden —
five non-reconciled compliance metrics, and an unclear distinction between
posture Recommendations and behavioural Alerts — independent of initial setup
complexity. Future work should treat setup complexity and ongoing
interpretive complexity as distinct, separately measured dimensions, since
this study observed the latter without a dedicated framework for quantifying
it.
