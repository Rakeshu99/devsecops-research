# Implementation Log — DevSecOps Pre-Pipeline Security Gate Research

**Student:** Rakesh Uday Kumar (A00047386)
**Supervisor:** Dr. Shivani Jaswal
**Module:** RESH-H6002-53441-TU437-PT-202520

---

## 22 June 2026 — Local Environment Setup

**Objective:** Provision an isolated Linux environment capable of running Docker, OWASP WebGoat, and Linux-kernel-dependent security tools (specifically Falco), and confirm the target application is reachable from the host machine.

### Step 1 — Hypervisor Consolidation

**Action:** Removed VMware Workstation Pro, retained VirtualBox as the sole hypervisor.

**Justification:** Running two hypervisors simultaneously offered no functional benefit for this project and consumed unnecessary disk space from prior, already-graded module VMs (Attacker-Kali, Target-WIN10, FireWall-pfSense, EAD-Server). VirtualBox is free, open source, and sufficient for all project requirements.

**Result:** Freed local disk space. Confirmed 78.4 GB free on host C: drive before VM creation.

---

### Step 2 — VM Provisioning

**Action:** Created a new VirtualBox VM named `devsecops-research-vm`.

**Specification:**

| Setting | Value |
|---|---|
| OS | Ubuntu 24.04.3 LTS (Server edition ISO, unattended install) |
| Base Memory | 6144 MB |
| Processors | 4 |
| Disk | 50 GB, dynamically allocated, VDI format |
| Network | NAT with port forwarding (SSH: 2222->22, WebGoat: 8080->8080, WebWolf: 9090->9090) |

**Justification:** Ubuntu was selected because Falco (the AI/ML runtime anomaly detection tool in the open-source stack) requires direct Linux kernel access and cannot run on Windows. Using a Linux VM also ensures the local testing environment matches the GitHub Actions Ubuntu runner used in the CI/CD pipeline, improving consistency between local and pipeline-based testing. Resource allocation (6GB RAM, 4 vCPU, 50GB disk) was sized to comfortably run Docker, WebGoat (a Java/Spring Boot application), and five security tools without resource contention, while remaining within the host laptop's 16GB RAM ceiling.

**Issue encountered:** Transient `watchdog: BUG: soft lockup` kernel warnings appeared twice during the unattended install (130s and 56s stalls on CPU#0). The installation self-recovered and completed successfully (`cloud-init finished`). No further action was required; attributed to host-level resource scheduling during install rather than a VM configuration fault.

**Screenshot:** `01-ubuntu-unattended-install-log.png`, `02-vm-login-success.png`, `02-disk-space-confirmed.png`

---

### Step 3 — Remote Access Configuration

**Action:** Installed `openssh-server` inside the VM and configured VirtualBox port forwarding (host port 2222 -> guest port 22) to allow SSH access from the Windows host terminal rather than working directly in the VirtualBox console window.

**Justification:** SSH access improves workflow efficiency (proper terminal scrollback, copy-paste reliability) and mirrors how a real engineer would interact with a remote Linux server or CI/CD runner — relevant to the SME-realistic operating model the project is evaluating.

**Command used:**
```bash
sudo apt install openssh-server -y
```

**Result:** Successful SSH connection established from Windows PowerShell using `ssh rakesh@localhost -p 2222`.

---

### Step 4 — System Update

**Command used:**
```bash
sudo apt update && sudo apt upgrade -y
```

**Result:** 51 pending packages updated successfully. No errors or broken dependencies. Kernel confirmed up to date; no reboot required.

**Screenshot:** `03-system-update-complete.png`

---

### Step 5 — Docker Installation

**Action:** Installed Docker Engine from Docker's official APT repository (not Ubuntu's default repository, which carries an outdated version).

**Commands used:**
```bash
sudo apt install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -aG docker $USER
newgrp docker
```

**Result:** Docker Engine, CLI, containerd, Buildx plugin, and Compose plugin installed successfully. User added to `docker` group to allow running Docker commands without `sudo`.

**Verification:**
```bash
docker run hello-world
```
Output confirmed: `Hello from Docker! This message shows that your installation appears to be working correctly.`

**Screenshot:** `04-docker-install-complete.png`, `05-docker-hello-world.png`

---

### Step 6 — WebGoat Deployment

**Command used:**
```bash
docker run -d -p 8080:8080 -p 9090:9090 --name webgoat webgoat/webgoat
```

**Result:** WebGoat image pulled successfully and container started. Application logs confirmed both Tomcat services started correctly:
- Port 9090 (WebWolf) — started in ~53 seconds
- Port 8080 (WebGoat) — started in ~87 seconds total

**Issue encountered:** `docker ps` initially reported container status as "unhealthy". Investigation via `docker logs webgoat` confirmed this was a false negative — the container's health check executed before the Spring Boot application had finished initialising (WebGoat's Java/Spring Boot startup takes approximately 90 seconds end-to-end across both Tomcat instances). Application logs confirmed successful startup with no errors: `Started StartWebGoat in 33.36 seconds`.

**Screenshot:** `06-webgoat-container-start.png`, `06b-webgoat-startup-logs.png`

---

### Step 7 — Browser Access Verification

**Action:** Added port forwarding rules in VirtualBox (8080->8080, 9090->9090) and accessed WebGoat from a browser on the Windows host.

**URL:** `http://localhost:8080/WebGoat/login`

**Result:** Login page loaded successfully. Registered a new user account and confirmed access to the WebGoat dashboard, showing all OWASP Top 10 vulnerability categories (A1-A10) available for testing.

**Screenshot:** `07-webgoat-browser-access.png`, `08-webgoat-dashboard.png`

---

## Summary — Environment Status as of 22 June 2026

| Component | Status |
|---|---|
| Ubuntu 24.04 VM (6GB RAM, 4 vCPU, 50GB disk) | Provisioned and operational |
| SSH remote access | Working |
| Docker Engine | Installed and verified |
| OWASP WebGoat | Deployed, accessible, user account created |

**Relevance to research:** This establishes the controlled test environment required for Phase 2 of the Design Science Research methodology (open-source stack construction and testing). The environment is now ready for the first security tool — Semgrep — to be integrated and run against WebGoat's source code as the first detection capability measurement (Metric 1).

---

## 22 June 2026 (continued) — Semgrep Integration (Tool 1 of 5)

**Objective:** Install Semgrep and run a static code analysis scan against WebGoat's source code to capture the first detection capability data point for the open-source stack.

**Steps performed:**
1. Cloned WebGoat source repository (`github.com/WebGoat/WebGoat`) into the VM — 48,813 objects, full Java/Spring Boot codebase.
2. Installed Semgrep via `pip3 install semgrep --break-system-packages`. Required adding `~/.local/bin` to `PATH` (`source ~/.bashrc`) since `pip3` installed scripts there by default.
3. Ran `semgrep --config=p/owasp-top-ten` against the WebGoat source tree.

**Result:** 20 findings (all marked Blocking) across 974 git-tracked files, using 160 applicable rules from the free Community ruleset (544 rules total). Findings spanned SQL injection (9), path traversal (2), insecure cryptography (MD5 usage), SSRF, open redirect, a session/trust-boundary issue, a Spring Actuator misconfiguration, an insecure HTTP link, and — notably — a shell injection vulnerability in WebGoat's own `.github/workflows/release.yml` GitHub Actions file, directly relevant to the CI/CD pipeline security risks this research investigates.

**Issues encountered:** Three large third-party JavaScript libraries (`ace.js`, `jquery-ui-1.10.4.js`, `wysihtml5-0.3.0.js`) triggered scan timeouts and were excluded from full rule coverage after three timeout errors each.

**Full results and analysis:** `metrics/results/semgrep-results.md`, raw output `metrics/results/semgrep-findings-readable.txt`

**Relevance to research:** First concrete data point for Metric 1 (Detection Capability — 20 findings, correctly identifying several of WebGoat's deliberately introduced weaknesses) and Metric 4 (Pipeline Overhead — 78 seconds for 974 files on local VM). The free-tier rule limitation (1,803 Pro rules unavailable without a paid account) is directly relevant to Metric 5 (Cost) and Metric 6 (SME Suitability).

---

## 22 June 2026 (continued) — Trivy Integration (Tool 2 of 5)

**Objective:** Install Trivy and scan the WebGoat Docker image for known CVEs in OS packages and Java dependencies, providing a second, complementary data point to Semgrep's code-level findings.

**Steps performed:**
1. Attempted install via the official Trivy install script — failed with a DNS resolution error (`Could not resolve host: get.trivy.dev`).
2. Switched to Trivy's official APT repository as a fallback. Successfully installed Trivy v0.71.2.
3. Ran `trivy image webgoat/webgoat --severity CRITICAL,HIGH` against the running WebGoat image.
4. Initial scan failed with `context deadline exceeded` (default 5-minute timeout). Re-ran with `--timeout 15m`.

**Result:** 62 vulnerabilities total — 11 (all HIGH) in the Ubuntu 24.04 OS layer, and 51 (39 HIGH, 12 CRITICAL) in `webgoat.jar`'s Java dependencies. Most significant CRITICAL findings: CVE-2013-7285 (XStream 1.4.5, remote code execution via insecure deserialization), CVE-2026-41293 (Tomcat, HTTP/2 header validation bypass), CVE-2025-41232 (Spring Security Core, authorization bypass), CVE-2026-22732 (Spring Security Web, policy bypass), CVE-2026-40477 (Thymeleaf, server-side template injection).

**Issues encountered:**
- Official install script unreliable (DNS resolution failure) — required fallback to APT method.
- Default timeout insufficient for this image's size and complexity — required manual override.
- First-run database downloads (97 MiB vulnerability DB + 884 MiB Java DB) added approximately 9 minutes of one-time setup overhead before any scanning began. Both databases are cached locally afterward (Java DB cached for 3 days).
- Secret scanning flagged `webgoat.jar` (142 MB) as inefficient to scan for secrets at that size, recommending `--scanners vuln` to disable secret scanning when only vulnerability data is needed.

**Full results and analysis:** `metrics/results/trivy-results.md`, raw output `metrics/results/trivy-findings-readable.txt`

**Relevance to research:** Demonstrates that Semgrep (code-level analysis) and Trivy (dependency/image-level analysis) are complementary rather than overlapping — zero overlap in vulnerability classes found between the two tools. This is an important methodological point for the final comparative analysis: raw finding counts should not be compared directly across tools without accounting for what layer of the software supply chain each tool actually inspects. The install script failure and timeout issues are concrete, citable evidence for Metric 3 (Setup Complexity).

---

## 28 June 2026 — Trufflehog Integration (Tool 3 of 5)

**Objective:** Install Trufflehog and scan WebGoat's source code for hardcoded secrets and credentials, then supplement with a controlled test to generate a genuine detection-capability data point.

**Steps performed:**
1. Installed Trufflehog v3.95.6 via the official install script. Initial attempt failed with a permissions error (`cannot create regular file '/usr/local/bin/trufflehog': Permission denied`) — resolved by re-running with `sudo`.
2. First scan attempt failed with an updater error (`cannot move binary`) caused by Trufflehog's auto-update check attempting to write to a root-owned binary path. Resolved using the `--no-update` flag.
3. Ran `trufflehog filesystem . --no-update` against the WebGoat source tree.
4. An initial run produced misleading duplicate results because the scan's own output file was written into the directory being scanned and then re-scanned in the same pass. Resolved by directing output to `/tmp/` instead of inside the target directory.
5. Created a controlled test (`test-secrets-controlled/fake-credentials.env`) containing four deliberately injected fake secrets to directly measure detection capability, since WebGoat itself does not contain realistic hardcoded operational secrets.
6. Ran Trufflehog against the controlled test file.

**Result — WebGoat scan:** 2 findings (both unverified), both JWT tokens embedded in WebGoat's own JWT lesson documentation (`JWT.html`, `JWT_libraries.adoc`) — intentional teaching content, not leaked operational credentials. Scan covered 151.6 MB across 12,362 chunks in 41 seconds.

**Result — controlled test (initial version):** 1 of 4 detected, using an AWS access key as one of the four planted secrets.

**Correction (7 July 2026):** The controlled test was rebuilt using an Azure Storage connection string in place of the AWS key, since the project's cloud-native comparison stack is Azure-based and the original test did not actually measure the Azure-specific claim being reported. Rebuilt test file: GitHub token, Azure Storage connection string, database password, Slack webhook — committed to the repository (`test-secrets-controlled/fake-credentials.env`) for reproducibility, unlike the original which was not version-controlled. **Corrected result: 2 of 4 (50%) detected** — GitHub token and Slack webhook detected; Azure Storage connection string and database password missed. Raw output: `metrics/results/trufflehog-controlled-test-v2.json`.

**Issues encountered:** Permissions error on install (resolved with `sudo`); auto-updater runtime error (resolved with `--no-update`); self-scan duplication on first WebGoat run (resolved by redirecting output outside the scan target); original controlled test used the wrong cloud provider's credential format and was not committed to version control, requiring correction (see 7 July entry below).

**Full results and analysis:** `metrics/results/trufflehog-results.md`, raw output `metrics/results/trufflehog-findings-readable.txt` and `metrics/results/trufflehog-controlled-test-v2.json`

**Relevance to research:** The WebGoat scan result demonstrates that WebGoat is not, on its own, a sufficient test case for evaluating secret-detection tools, since its deliberate vulnerabilities are concentrated in code logic and dependency issues rather than hardcoded credentials. The corrected controlled test provides a genuine, reproducible detection-capability data point (Metric 1): strong detection of well-known platform token formats (GitHub, Slack) but no detection of the Azure Storage connection string format or unstructured passwords. The Azure detection gap is directly relevant given this project's cloud-native comparison stack is Azure-based, and is significant for Metric 6 (SME Suitability).

---

## 28 June 2026 (continued) — Falco Integration (Tool 4 of 5)

**Objective:** Install Falco and verify runtime anomaly detection capability against the running WebGoat container — the only tool in the open-source stack operating at runtime rather than at the pre-pipeline/build stage.

**Steps performed:**
1. Installed Falco v0.44.1 via the official APT repository (chosen directly over the install script, having learned from Trivy's earlier DNS-related install script failure).
2. Falco's installer automatically selected the modern eBPF driver (`falco-modern-bpf.service`) rather than a kernel module — more portable for a VM environment, no kernel module build/load step required.
3. Confirmed service active via `systemctl status falco` — rules loaded with valid schema, monitoring syscalls across all CPUs.
4. Attempted to watch live alerts via `journalctl -u falco` and `journalctl -fu falco` — both returned no entries despite the service being confirmed active and consuming CPU.
5. Investigated `/etc/falco/falco.yaml` and found `syslog_output: enabled: true` — Falco's output goes to `/var/log/syslog`, not tagged under the `falco` systemd unit in a way `journalctl -u falco` could filter.
6. Switched to `sudo tail -50 /var/log/syslog | grep -i falco` — found Falco had been logging correctly the entire time.
7. Triggered a test anomaly: spawned an interactive shell inside the running WebGoat container (`docker exec -it webgoat /bin/bash`), attempted to read `/etc/shadow` (denied — confirms WebGoat runs as non-root `webgoat` user), then exited.

**Result:** Falco successfully detected both shell-spawn attempts, logging full forensic context for each:
```
Notice A shell was spawned in a container with an attached terminal |
evt_type=execve user=webgoat user_uid=1001 process=bash
container_id=4ecae51bbf66 container_name=webgoat
container_image_repository=webgoat/webgoat container_image_tag=latest
```

**Issues encountered:** The logging-destination mismatch (syslog vs. journald unit) cost significant troubleshooting time and is a genuine, citable setup complexity finding — Falco was working correctly throughout, but its default alert location is not obvious from `systemctl status` alone.

**Full results and analysis:** `metrics/results/falco-results.md`, raw output `metrics/results/falco-detection-results.txt`

**Relevance to research:** Falco is methodologically distinct from the previous three tools in this stack — it detects anomalous behaviour in a running system rather than scanning static code, dependencies, or committed secrets. This demonstrates defence-in-depth across the software lifecycle but also means its pipeline overhead (Metric 4) is better characterised as continuous resource consumption (observed: ~46MB memory, ~48s CPU time over 13 minutes of monitoring — low overhead). Detection of the shell-spawn event required no custom rule configuration, demonstrating strong out-of-the-box capability for well-known anomaly patterns (Metric 1). The logging-destination friction point is directly relevant to Metric 3 (Setup Complexity) and Metric 6 (SME Suitability).

---

## 29 June 2026 — OPA Integration (Tool 5 of 5 — Open-Source Stack Complete)

**Objective:** Install OPA, author a custom Rego policy targeting CI/CD security risk, and validate it against both a true-positive and true-negative test case — completing the final tool in the open-source stack.

**Steps performed:**
1. Installed OPA v0.68.0 via direct binary download (avoiding package manager dependency issues encountered with Trivy and Falco earlier).
2. Authored a custom Rego policy (`github-actions-security.rego`) targeting the same risk class Semgrep identified independently in Tool 1: untrusted `github` context data used directly in a `run:` shell step without sanitisation.
3. Converted WebGoat's `.github/workflows/release.yml` from YAML to JSON using a one-line Python script with `pyyaml`, since OPA evaluates structured JSON input.
4. Ran the policy against the converted WebGoat workflow (true-positive test).
5. Authored a minimal "clean" workflow JSON with no risky pattern and ran the same policy against it (true-negative / false-positive control test).

**Result — true positive:** OPA correctly flagged the `release` job's risky `run:` step, identifying the exact same line Semgrep had flagged independently using a completely different detection mechanism (AST-based static analysis vs. declarative policy evaluation).

**Result — true negative:** Policy returned an empty result (`[]`) against the clean control workflow, confirming no false positives.

**Issues encountered:** None of significance. The primary friction point for OPA is conceptual rather than technical: unlike the other four tools, OPA has no out-of-the-box security ruleset and requires policy logic to be authored from scratch.

**Full results and analysis:** `metrics/results/opa-results.md`, policy file `stacks/opensource/opa/github-actions-security.rego`, reusable script `stacks/opensource/opa/run-opa-evaluation.sh`

**Relevance to research:** This result provides meaningful cross-validation — two independent tools using entirely different detection methods identified the same real vulnerability, strengthening confidence that the finding is genuine rather than a tool-specific artefact. The lack of an out-of-the-box ruleset is a significant finding for Metric 3 (Setup Complexity) and Metric 6 (SME Suitability): OPA's practical value for an SME is entirely dependent on the policy-authoring effort invested, in contrast to Semgrep, Trivy, Falco, and Trufflehog, all of which provided functional detection immediately using community-maintained or default rules.

---

## Milestone — Open-Source Stack Complete

All five open-source tools (Semgrep, Trivy, Trufflehog, Falco, OPA) are now installed, tested, and documented with real findings against WebGoat. This completes Phase 2 of the Design Science Research methodology (open-source stack construction and testing).

---

## 29 June 2026 (continued) — GitHub Actions Pipeline Build

**Objective:** Build the baseline and open-source stack GitHub Actions pipelines, moving from local VM testing to actual CI/CD pipeline execution — the context this project's research question specifically addresses.

### Baseline Pipeline (`baseline.yml`)

**Purpose:** Control condition. Measures pipeline execution time with zero security tooling, establishing the overhead baseline against which the security stack's added time is measured (Metric 4 — Pipeline Overhead).

**Result:** Pipeline ran successfully in 11 seconds on GitHub's Ubuntu runner. All steps completed: checkout, simulated build, timestamping. Confirmed consistent across 3 runs (11s, 12s, 15s — average ~12 seconds).

**Screenshot evidence:** `metrics/results/screenshots/07-pipeline-integration/01-baseline-pipeline-run.png`

---

### Open-Source Stack Pipeline (`opensource-stack.yml`)

**Purpose:** The actual research artefact — the pre-pipeline security gate that this project's research question describes. Integrates all four applicable open-source tools (Semgrep, Trivy, Trufflehog, OPA) as parallel jobs in a GitHub Actions CI/CD pipeline.

**Note on Falco:** Falco is not included in the GitHub Actions pipeline because it requires kernel-level access (eBPF probes) which is not available on GitHub's hosted Ubuntu runners. Falco's runtime monitoring is documented separately as a local VM finding. This is itself a relevant SME suitability observation — Falco cannot be directly integrated into a standard hosted CI/CD pipeline without self-hosted runners or a dedicated agent.

**Tools integrated:**
- Semgrep — OWASP Top Ten ruleset, JSON output uploaded as artifact
- Trivy — filesystem scan, CRITICAL and HIGH severity, JSON output uploaded as artifact
- Trufflehog — filesystem secret scan, JSON output uploaded as artifact
- OPA — custom Rego policy evaluation against workflow YAML, results uploaded as artifact

**Design decision:** All four jobs run in parallel (not sequential) to minimise total pipeline time. Each job uploads its results as a GitHub Actions artifact for download and analysis.

**Pipeline timing results (initial, superseded — see 7 July entry):**

| Pipeline | Runs | Average Time |
|---|---|---|
| Baseline (no security tools) | 3 runs | ~12 seconds |
| Open-Source Security Stack | 2 runs | ~26 seconds |
| **Net security gate overhead** | | **~14 seconds per pipeline run** |

**Individual job timing (initial, superseded):**

| Tool | Time | Notes |
|---|---|---|
| Semgrep | 20s | Downloads ruleset on each run |
| Trivy | 22s | Downloads vulnerability DB on each run |
| Trufflehog | 8s | Lightweight |
| OPA | 8s | Near-instantaneous |
| **Total (parallel)** | **27s** | |

**Important note added 7 July 2026:** these initial timing figures were later discovered to have been measured while the pipeline's checkout step was not correctly pulling in the WebGoat submodule (see entry below) — meaning the tools were running against a repository with no WebGoat content present. These figures are retained here for transparency but are superseded and must not be used in the comparative analysis. Corrected timing is pending re-measurement under fixed conditions.

**Screenshot evidence:**
- `metrics/results/screenshots/07-pipeline-integration/01-baseline-pipeline-run.png`
- `metrics/results/screenshots/07-pipeline-integration/02-opensource-pipeline-runs.png`
- `metrics/results/screenshots/07-pipeline-integration/03-opensource-pipeline-job-timings.png`

---

## 30 June – 6 July 2026 — Azure GHAS / CodeQL Integration

**Objective:** Begin Phase 3 (Azure cloud-native stack) with the GitHub-native component of the Azure comparison — GitHub Advanced Security's CodeQL — since it required WebGoat to be present as an analysable target within the repository for the first time.

**Steps performed:**
1. Added WebGoat as a Git submodule at `app/webgoat` (commit `8211cf2`), pointing to the upstream `WebGoat/WebGoat` repository.
2. Enabled GitHub Advanced Security and Dependabot alerts/dependency graph under repository Settings.
3. Configured a CodeQL Advanced workflow (`codeql.yml`) with `submodules: recursive` on checkout (correctly configured from the start, unlike the open-source stack pipeline — see below), JDK 25, and a manual Maven build after troubleshooting build-mode and JDK version iterations.
4. Ran the CodeQL scan against the WebGoat submodule.

**Result:** 71 findings total — 3 Critical (XXE injection in `CommentsCache.java`, deserialization x2), 52 High (dominated by repeated path traversal instances across multiple files, not 52 distinct vulnerability types), 16 Medium (11 in WebGoat application code — insecure cookies, missing HttpOnly; 5 in the repository's own `.github/workflows/opensource-stack.yml` — missing workflow permissions, a genuine finding in the project's own CI configuration rather than WebGoat).

**Screenshot evidence:** `metrics/results/screenshots/08-azure-ghas/01-codeql-setup-enabled.png` through `05-codeql-medium.png`

**Relevance to research:** This is the first Azure-stack data point, directly comparable to Semgrep's code-level findings. CodeQL's broader default scan scope (flagging a real misconfiguration in the project's own CI workflow, which none of the open-source tools were configured to catch) is itself a relevant SME-suitability observation, discussed further in the comparative analysis. As with Trivy vs. Semgrep, raw finding counts between CodeQL (71) and Semgrep (20) are not directly comparable without accounting for scan scope and rule depth differences between the two tools.

---

## 7 July 2026 — CI Pipeline Verification and Correction

**Objective:** Verify that the open-source stack's automated GitHub Actions pipeline (`opensource-stack.yml`) actually scans WebGoat correctly, following completion of the CodeQL/GHAS phase, before proceeding to the remaining Azure stack components.

**Issue found:** The pipeline's checkout steps (Semgrep, Trivy, Trufflehog, OPA jobs) lacked `submodules: recursive`. WebGoat was not added to the repository until 7 July, meaning every automated pipeline run prior to this date — including the ones that produced the "initial" timing figures above — executed against a repository with no WebGoat content present at all. This was discovered while cross-checking CI artifacts against the manually-verified tool results documented in the sections above.

**Verification process:** Each tool's previously reported manual findings (Semgrep 20, Trivy 62, Trufflehog 2 WebGoat findings, OPA true-positive/negative) were re-confirmed against their original raw output logs and were found to be genuine and accurate — they had been generated by running each tool directly against a manually-cloned copy of WebGoat on the VM, independent of the (at-the-time non-functional) automated pipeline. The automated pipeline itself, however, had never successfully scanned WebGoat until the fixes below were applied.

**Fixes applied:**
1. Added `submodules: recursive` to all four checkout steps in `opensource-stack.yml`.
2. **Semgrep:** even with the submodule correctly checked out to disk, Semgrep's default file-discovery only considers files tracked by the *current* repository's git index — a submodule's files are tracked by the submodule's own `.git`, so they were silently excluded. Fixed by adding `--no-git-ignore` to the scan command, forcing Semgrep to scan the actual filesystem rather than relying on git-tracked-file discovery.
3. **Trivy:** the pipeline used `trivy fs .` (filesystem scan), which — once WebGoat's Java source was actually present — attempted live Maven dependency resolution against Maven Central and failed with a `429 Too Many Requests` error (GitHub-hosted runners share IP ranges, exhausting Maven's public rate limit). Fixed by switching to `trivy image webgoat/webgoat --timeout 15m`, matching the Docker-image-based method already used and documented in the original manual Trivy scan (see 22 June entry) — this reads the pre-built image's dependency manifest directly with no live external resolution required.
4. **Trufflehog and OPA** required no command changes; the submodule checkout fix alone was sufficient for Trufflehog (it does not exclude submodule content the way Semgrep's default mode does), and OPA's job was never intended to scan WebGoat in the first place (it evaluates the repository's own workflow YAML, by design).

**Re-verification result:** Following the fixes, a fresh pipeline run was triggered and all four artifacts were downloaded and inspected directly:
- **Semgrep:** confirmed scanning real `app/webgoat/src/...` paths, producing the same categories of findings as the original manual scan (SQL injection, path traversal, MD5 usage, SSRF, the `release.yml` shell injection).
- **Trivy:** confirmed real XStream, Tomcat, and Spring Security CVEs against `home/webgoat/webgoat.jar/BOOT-INF/lib/...` paths, matching the original manual scan.
- **Trufflehog:** confirmed the same two JWT findings at the same file paths and line numbers (`JWT.html:323`, `JWT_libraries.adoc:40`) as the original manual scan.
- **OPA:** confirmed empty result (`[]`) is correct and expected, since this job evaluates the pipeline's own workflow file, not WebGoat.

**Additional correction:** The Trufflehog controlled secret test (originally run 28 June using an AWS access key as one of the four planted secrets) was identified as inconsistent with the project's Azure-based cloud-native comparison stack, and had not been committed to version control. Rebuilt using an Azure Storage connection string in its place, committed to the repository for reproducibility (`test-secrets-controlled/fake-credentials.env`, `metrics/results/trufflehog-controlled-test-v2.json`). Corrected result: 2 of 4 (50%) detected.

**Issues encountered:** This verification pass took considerably longer than expected due to the compounding nature of the problem — the submodule bug alone would have been a single fix, but it surfaced two further, tool-specific scan-target issues (Semgrep's git-tracked-file limitation, Trivy's live dependency resolution) that only became visible once WebGoat was genuinely present for the pipeline to scan.

**Relevance to research:** This is a legitimate Design Science Research iteration — build, evaluate, discover flaw, refine, re-evaluate — applied to the evaluation instrument itself (the CI pipeline) rather than to WebGoat. It also produces a directly citable Metric 3 (Setup Complexity) finding: correctly wiring open-source security tools into a real CI/CD pipeline against a codebase that includes git submodules required non-obvious, tool-specific configuration beyond the basic checkout step, a friction point an SME team would need to budget time for.

**Next steps:**
1. Re-measure pipeline timing under corrected conditions (previous 12s/27s figures are void).
2. Update README status table to reflect verified CI pipeline completion.
3. Proceed with remaining Azure stack components: Dependabot, Defender for DevOps, Defender for Cloud, Microsoft Sentinel, Azure Policy.
4. Build Azure stack GitHub Actions pipeline for equivalent timing comparison.
5. Conduct comparative analysis across all six metrics.

---

## 7 July 2026 (continued) — Dependabot / GitHub Dependency Graph Limitation

**Objective:** Enable Dependabot alerts for WebGoat's Java/Maven dependencies as part of the Azure/GitHub-native stack comparison, following the CI pipeline verification above.

**Steps performed:**
1. Enabled Dependabot alerts and Dependency graph under repository Settings → Advanced Security.
2. Added `.github/dependabot.yml` configuring a Maven ecosystem entry pointed at `/app/webgoat`, the submodule's location, to attempt to target WebGoat's `pom.xml`.
3. Waited for GitHub's scan to run and checked both the Dependabot alerts page and the Dependency graph directly.

**Finding:** The Dependabot alerts page returned zero alerts, and the Dependency graph's Dependencies tab continued to show only 7 dependencies — all GitHub Actions references from the repository's own workflow files, none from WebGoat's `pom.xml`. Checking the Dependabot tab specifically showed two "Version update" jobs had run successfully against the Maven ecosystem entry with "No PRs affected," confirming the `dependabot.yml` path was valid and readable, but this did not translate into populated dependency graph entries or vulnerability alerts.

Research into GitHub's documented behavior confirmed this is expected, not a misconfiguration: **the native GitHub dependency graph does not automatically scan or parse package manifests located inside Git submodules**, since GitHub evaluates each repository in isolation and treats a submodule strictly as a pointer (a commit reference) to an external repository, rather than as a local directory containing scannable manifest files. Dependabot's version-update bot and the Dependency Graph / alerting feature are more decoupled than initial configuration suggested — a `dependabot.yml` directory override is sufficient to trigger version-update jobs against a submodule path, but does not cause the Dependency Graph itself to index that path for alerting purposes.

**Workarounds identified but not adopted:**
1. **GitHub Dependency Submission API** — a custom GitHub Action step could check out the submodule and manually submit a dependency snapshot via API, bypassing native auto-discovery entirely.
2. **Enable the dependency graph on the submodule's native repository** — not viable, since this requires administrative access to `github.com/WebGoat/WebGoat`, which this project does not own.

Both were assessed as disproportionate effort relative to their contribution to this comparison, given Trivy's Docker-image-based scan already provides equivalent dependency-vulnerability coverage for WebGoat (see 22 June entry, 62 findings).

**Corroboration check:** WebGoat's own public upstream repository has its dependency graph enabled by default (a standard GitHub behavior for public repositories), showing 93 total Maven dependencies. Searching this graph and the repository's source directly confirmed the same vulnerable dependency Trivy identified — `xstream 1.4.5` in `pom.xml`, line 111 — including a source code comment on the following line stating "do not update necessary for lesson," confirming WebGoat's maintainers deliberately hold this dependency at a vulnerable version for teaching purposes. This triangulates the finding across three independent sources: Trivy's image scan, GitHub's dependency graph on the upstream repository, and the source code itself.

**Full evidence:** `metrics/results/screenshots/09-dependabot/`

**Relevance to research:** This is a genuine, citable SME suitability finding (Metric 6), and arguably more valuable to the comparative analysis than a working Dependabot alert would have been. GitHub-native dependency scanning has an undocumented-at-setup-time gap for any project using git submodules to include third-party or vendored source code — a common pattern for exactly the kind of resource-constrained SME team this research targets. A team relying on Dependabot alone, without awareness of this limitation, would have a false sense of dependency-vulnerability coverage for any submodule-included code. This is directly relevant to Metric 3 (Setup Complexity) as well: correctly diagnosing this limitation required distinguishing between two related-but-distinct GitHub features (Dependabot version updates vs. the Dependency Graph/alerts pipeline) that are not clearly separated in GitHub's own UI.

**Next steps:**
1. Proceed with Defender for Cloud environment connection (GitHub integration for Defender for DevOps).
2. Enable Defender for Cloud CSPM plan.
3. Set up Microsoft Sentinel (Log Analytics workspace, then Sentinel onboarding).
4. Configure Azure Policy (built-in Security Benchmark initiative).
5. Build `azure-stack.yml` pipeline for equivalent timing comparison against the open-source stack.
6. Conduct comparative analysis across all six metrics.

---

## 8 July 2026 — Defender for Cloud GitHub Connector Setup

**Objective:** Connect Microsoft Defender for Cloud to the project's GitHub repository, enabling the Defender CSPM plan as the next component of the Azure cloud-native stack.

**Steps performed:**
1. Navigated to Defender for Cloud → Environment settings → Add environment → GitHub.
2. Configured connector `devsecopsresearch-gh`, resource group `devsecops-research-rg`, initial location North Europe.
3. Authorized the Microsoft Security DevOps GitHub App, scoped to "Only select repositories" → `devsecops-research` only (not all repositories), with read-only permissions to Dependabot alerts, metadata, secret scanning alerts, and security events.
4. Selected Defender CSPM capability (listed as "Free during preview" at time of setup).
5. Clicked Create.

**Issue found:** Connector creation failed with a "'deny' Policy action" error. Investigating via the Azure Activity Log (JSON detail view) identified the cause: a system-level policy assignment named `sys.regionrestriction` ("Allowed resource deployment regions"), applied automatically to the Azure for Students subscription, restricts resource deployment to a specific allow-list of regions: Switzerland North, Sweden Central, Poland Central, Canada Central, Spain Central. Neither North Europe nor West Europe — both of which appeared as selectable options in the connector wizard's Location dropdown — are on this list, meaning the UI did not filter location options by actual policy-permitted regions, allowing an invalid selection to be made and only failing at creation time.

**Fix applied:** Recreated the connector with Location set to Sweden Central. Connector created successfully on retry.

**Result:** Connector status confirmed "Connected," 1/1 Defender plans active, 2 resources discovered. The "DevOps security" dashboard subsequently populated with 75 total findings (3 Critical, 52 High, 20 Medium, 0 Low): 71 Code findings, 4 Infrastructure as Code findings, 0 Secret findings, 0 Dependency findings.

**Cross-check against CodeQL:** Comparing Defender for Cloud's Code findings (71, with Critical=3 and High=52) against the CodeQL results documented in the 30 June – 6 July entry above (71 findings, Critical=3, High=52) shows an exact match on Critical and High counts. This confirms Defender for Cloud's "DevOps security" dashboard substantially surfaces CodeQL's own scan results rather than running a fully independent detection engine — the connector's scanner list (`eslint, bandit, templateanalyzer, checkov, trivy`) includes additional lightweight scanners (likely accounting for the small increase from 71 to 75 total findings, and the Medium count difference of 16 vs 20), but the core code-vulnerability detection is CodeQL-derived.

**Verification of individual findings:** Drilled into the Recommendations view (Security posture → GitHub environment filter → Vulnerabilities tab) to confirm findings were live and specific, not a cached or placeholder count. Confirmed individual findings including "Arbitrary file access during archive extraction ('Zip Slip')," "Deserialization of user-controlled data," "Disabled Spring CSRF protection," and others, each attributed directly to the `devsecops-research` repository — matching finding categories already documented from the CodeQL scan.

**Full evidence:** `metrics/results/screenshots/10-defender-devops/`

**Relevance to research:** Two citable findings for this phase. First, Metric 3 (Setup Complexity): the region-restriction policy failure was not discoverable from the connector wizard's own UI (which offered invalid region choices) and required inspecting the Azure Activity Log's raw JSON to diagnose — a non-trivial troubleshooting step for a team without prior Azure Policy experience. Second, and more significant for Metric 6 (SME Suitability) and the overall comparative analysis: Defender for Cloud's headline "75 findings" should not be read as evidence of independent, additive detection capability beyond CodeQL — the substantial overlap means an SME already running CodeQL directly would gain centralised dashboarding and a small number of additional IaC/dependency scanner findings from enabling Defender for Cloud, but not a materially different security posture. This directly informs the "is a paid/cloud-native security gate worth it over free, self-hosted tools" question at the core of this dissertation's research question.

**Next steps:**
1. Set up Microsoft Sentinel — Log Analytics workspace, then Sentinel onboarding (31-day free trial, 10 GB/day cap; monitor against Azure budget alert).
2. Configure Azure Policy — assign built-in Security Benchmark initiative.
3. Build `azure-stack.yml` GitHub Actions pipeline for equivalent timing comparison against the open-source and baseline pipelines.
4. Conduct comparative analysis across all six metrics.
