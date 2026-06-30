# Deliberately Introduced Vulnerabilities — Test Environment Documentation

**Application:** OWASP WebGoat (webgoat/webgoat:latest)
**Pipeline:** GitHub Actions
**Purpose:** This document records the vulnerabilities present in the test environment, their source, and their relevance to the six evaluation metrics. These vulnerabilities serve as the ground truth against which both the open-source and Azure cloud-native security stacks are evaluated.

---

## Important Note on Vulnerability Source

OWASP WebGoat is a deliberately insecure application maintained by OWASP specifically for security training and tool evaluation. Its vulnerabilities are **intentionally built in by design**, not injected by the researcher. This is academically appropriate for this project for the following reasons:

1. **Documented and reproducible** — every vulnerability in WebGoat is publicly documented, allowing precise measurement of what each tool should detect
2. **Realistic** — the vulnerability types (SQL injection, insecure dependencies, path traversal) represent real-world risks, not synthetic test cases
3. **OWASP-aligned** — both WebGoat's vulnerabilities and this project's threat model are based on OWASP standards (OWASP Top 10, OWASP CI/CD Top 10), ensuring methodological consistency
4. **Enterprise-representative** — WebGoat is Java/Spring Boot, the most common technology stack in enterprise SME environments

---

## Vulnerability Inventory

### V1 — SQL Injection (Multiple Instances)

| Attribute | Detail |
|---|---|
| Type | SQL Injection — A03:2021 OWASP Top 10 |
| Source | WebGoat's SQL Injection lesson module |
| Files affected | `SqlInjectionLesson5a.java`, `SqlInjectionLesson5b.java`, `SqlInjectionLesson8.java`, `SqlInjectionLesson9.java`, `SqlInjectionLesson10.java`, `SqlInjectionChallenge.java`, `Assignment5.java`, `Servers.java` |
| Detection method | Semgrep — `java.lang.security.audit.formatted-sql-string` and `java.spring.security.injection.tainted-sql-string` rules |
| Findings | 9 findings across 7 files |
| Severity | High |
| Why included | SQL injection is the most prevalent injection class (OWASP A03) and represents the most common code-level vulnerability in enterprise Java applications. It tests Semgrep's ability to trace tainted data flows from HTTP request parameters through to database query construction. |

---

### V2 — CI/CD Pipeline Shell Injection

| Attribute | Detail |
|---|---|
| Type | GitHub Actions shell injection — OWASP CI/CD Top 10, CICD-SEC-4 |
| Source | WebGoat's own release pipeline (`.github/workflows/release.yml`) |
| Files affected | `.github/workflows/release.yml`, line 24-27 |
| Detection method | Semgrep (`yaml.github-actions.security.run-shell-injection`) and OPA (custom Rego policy) — both independently |
| Findings | 1 finding, cross-validated by two independent tools |
| Severity | High — directly exploitable in CI/CD context |
| Why included | This is the most directly relevant vulnerability to this project's research motivation — the SolarWinds breach demonstrated that attackers can inject malicious code into CI/CD pipelines when untrusted input reaches shell execution. The fact that WebGoat's own pipeline contains this vulnerability makes it an authentic, non-synthetic test case. |

---

### V3 — Path Traversal

| Attribute | Detail |
|---|---|
| Type | Path Traversal — A01:2021 OWASP Top 10 (Broken Access Control) |
| Source | WebGoat's path traversal and file upload lesson modules |
| Files affected | `ProfileUploadRetrieval.java`, `FileServer.java` |
| Detection method | Semgrep — `java.lang.security.httpservlet-path-traversal` and `java.spring.security.injection.tainted-file-path` rules |
| Findings | 2 findings |
| Severity | High |
| Why included | Path traversal allows attackers to access files outside the intended directory — a common real-world vulnerability that tests Semgrep's ability to track user-controlled variables into file system operations. |

---

### V4 — Insecure Cryptography (MD5 Usage)

| Attribute | Detail |
|---|---|
| Type | Weak Cryptographic Algorithm — A02:2021 OWASP Top 10 (Cryptographic Failures) |
| Source | WebGoat's cryptography lesson module |
| Files affected | `HashingAssignment.java` |
| Detection method | Semgrep — `java.lang.security.audit.crypto.use-of-md5` rule (with auto-fix suggestion to SHA-512) |
| Findings | 1 finding |
| Severity | Medium |
| Why included | MD5 is cryptographically broken and unsuitable for security-sensitive hashing. Tests static analysis capability to identify insecure algorithm usage. |

---

### V5 — Server-Side Request Forgery (SSRF)

| Attribute | Detail |
|---|---|
| Type | SSRF — A10:2021 OWASP Top 10 |
| Source | WebGoat's JWT lesson module |
| Files affected | `JWTHeaderJKUEndpoint.java` |
| Detection method | Semgrep — `java.spring.security.injection.tainted-url-host` rule |
| Findings | 1 finding |
| Severity | High |
| Why included | SSRF allows attackers to make the server issue requests to unintended targets, potentially reaching internal services. Tests detection of user-controlled data reaching URL construction. |

---

### V6 — Open Redirect

| Attribute | Detail |
|---|---|
| Type | Unvalidated Redirect — A01:2021 OWASP Top 10 |
| Source | WebGoat's open redirect lesson module |
| Files affected | `OpenRedirectRealRedirect.java` |
| Detection method | Semgrep — `java.spring.security.audit.spring-unvalidated-redirect` rule |
| Findings | 1 finding |
| Severity | Medium |
| Why included | Unvalidated redirects are used in phishing attacks. The file even contains a comment `// Intentionally vulnerable: no validation` confirming this is a deliberate WebGoat vulnerability. |

---

### V7 — Outdated Dependencies with Known CVEs

| Attribute | Detail |
|---|---|
| Type | Vulnerable and Outdated Components — A06:2021 OWASP Top 10 |
| Source | WebGoat's bundled Java dependencies (`webgoat.jar`) |
| Libraries affected | XStream 1.4.5, Apache Tomcat 10.1.36, Spring Security 6.4.3/6.4.3, Thymeleaf 3.1.2 |
| Detection method | Trivy — container image scanning against NVD and GitHub Advisory databases |
| Findings | 62 total (12 CRITICAL, 39 HIGH in Java dependencies; 11 HIGH in Ubuntu OS packages) |
| Severity | CRITICAL and HIGH |
| Most severe | CVE-2013-7285 (XStream, CVSS 9.8 — remote code execution); CVE-2026-22732 (Spring Security Web — security policy bypass); CVE-2026-40477 (Thymeleaf — server-side template injection) |
| Why included | Outdated dependencies are the most common source of CRITICAL vulnerabilities in enterprise Java applications. Tests Trivy's ability to detect known CVEs in both OS packages and bundled application dependencies. |

---

### V8 — Hardcoded JWT Tokens in Source Code

| Attribute | Detail |
|---|---|
| Type | Sensitive Information in Source Code — credential exposure |
| Source | WebGoat's JWT lesson documentation |
| Files affected | `JWT.html`, `JWT_libraries.adoc` |
| Detection method | Trufflehog — JWT detector |
| Findings | 2 findings (both marked unverified — confirmed as intentional teaching examples, not operational credentials) |
| Severity | Low (non-operational, unverified) |
| Why included | Tests Trufflehog's secret-scanning capability. The "unverified" status is itself an important result — demonstrates Trufflehog's live verification feature correctly distinguishes between structurally-valid but non-operational tokens and genuinely active credentials. |

---

### V9 — Spring Boot Actuator Misconfiguration

| Attribute | Detail |
|---|---|
| Type | Security Misconfiguration — A05:2021 OWASP Top 10 |
| Source | WebGoat application configuration |
| Files affected | `application-webgoat.properties` |
| Detection method | Semgrep — `java.spring.security.audit.spring-actuator-dangerous-endpoints-enabled` rule |
| Findings | 1 finding |
| Severity | Medium |
| Why included | Exposed Spring Boot Actuator endpoints (`env`, `health`, `configprops`) can leak sensitive environment variables and configuration data. |

---

### V10 — Runtime Anomaly (Shell Spawned in Container)

| Attribute | Detail |
|---|---|
| Type | Runtime security anomaly — OWASP CI/CD Top 10, CICD-SEC-6 |
| Source | Controlled test — `docker exec -it webgoat /bin/bash` executed against the running container |
| Detection method | Falco — default rule "A shell was spawned in a container with an attached terminal" |
| Findings | 1 detection event (with full forensic context: user, process tree, container identity) |
| Severity | Notice (Falco severity level) |
| Why included | Spawning an interactive shell inside a running container is a classic indicator of unauthorized access or post-compromise activity. This is the primary runtime detection test case and the only dynamic (post-deployment) vulnerability in this test suite. |

---

## Summary Table

| ID | Vulnerability | Type | Tool | Findings |
|---|---|---|---|---|
| V1 | SQL Injection | Code-level | Semgrep | 9 |
| V2 | CI/CD Shell Injection | Pipeline | Semgrep + OPA | 1 (cross-validated) |
| V3 | Path Traversal | Code-level | Semgrep | 2 |
| V4 | Insecure Cryptography (MD5) | Code-level | Semgrep | 1 |
| V5 | SSRF | Code-level | Semgrep | 1 |
| V6 | Open Redirect | Code-level | Semgrep | 1 |
| V7 | Outdated Dependencies (CVEs) | Supply chain | Trivy | 62 |
| V8 | Hardcoded JWT Tokens | Secret exposure | Trufflehog | 2 (unverified) |
| V9 | Spring Actuator Misconfiguration | Configuration | Semgrep | 1 |
| V10 | Shell Spawned in Container | Runtime anomaly | Falco | 1 |

**Total unique vulnerability instances across all tools: 81**
**Note:** V2 was detected by both Semgrep and OPA independently — counted once in the total.
