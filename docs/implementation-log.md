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

| Setting     | Value                                                                              |
| ----------- | ---------------------------------------------------------------------------------- |
| OS          | Ubuntu 24.04.3 LTS (Server edition ISO, unattended install)                        |
| Base Memory | 6144 MB                                                                            |
| Processors  | 4                                                                                  |
| Disk        | 50 GB, dynamically allocated, VDI format                                           |
| Network     | NAT with port forwarding (SSH: 2222→22, WebGoat: 8080→8080, WebWolf: 9090→9090) |

**Justification:** Ubuntu was selected because Falco (the AI/ML runtime anomaly detection tool in the open-source stack) requires direct Linux kernel access and cannot run on Windows. Using a Linux VM also ensures the local testing environment matches the GitHub Actions Ubuntu runner used in the CI/CD pipeline, improving consistency between local and pipeline-based testing. Resource allocation (6GB RAM, 4 vCPU, 50GB disk) was sized to comfortably run Docker, WebGoat (a Java/Spring Boot application), and five security tools without resource contention, while remaining within the host laptop's 16GB RAM ceiling.

**Issue encountered:** Transient `watchdog: BUG: soft lockup` kernel warnings appeared twice during the unattended install (130s and 56s stalls on CPU#0). The installation self-recovered and completed successfully (`cloud-init finished`). No further action was required; attributed to host-level resource scheduling during install rather than a VM configuration fault.

**Screenshot:** `01-ubuntu-unattended-install-log.png`, `02-vm-login-success.png`, `02-disk-space-confirmed.png`

---

### Step 3 — Remote Access Configuration

**Action:** Installed `openssh-server` inside the VM and configured VirtualBox port forwarding (host port 2222 → guest port 22) to allow SSH access from the Windows host terminal rather than working directly in the VirtualBox console window.

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

**Action:** Added port forwarding rules in VirtualBox (8080→8080, 9090→9090) and accessed WebGoat from a browser on the Windows host.

**URL:** `http://localhost:8080/WebGoat/login`

**Result:** Login page loaded successfully. Registered a new user account and confirmed access to the WebGoat dashboard, showing all OWASP Top 10 vulnerability categories (A1–A10) available for testing.

**Screenshot:** `07-webgoat-browser-access.png`, `08-webgoat-dashboard.png`

---

## Summary — Environment Status as of 22 June 2026

| Component                                    | Status                                     |
| -------------------------------------------- | ------------------------------------------ |
| Ubuntu 24.04 VM (6GB RAM, 4 vCPU, 50GB disk) | Provisioned and operational                |
| SSH remote access                            | Working                                    |
| Docker Engine                                | Installed and verified                     |
| OWASP WebGoat                                | Deployed, accessible, user account created |

**Relevance to research:** This establishes the controlled test environment required for Phase 2 of the Design Science Research methodology (open-source stack construction and testing). The environment is now ready for the first security tool — Semgrep — to be integrated and run against WebGoat's source code as the first detection capability measurement (Metric 1).

**Next steps:**

1. Create GitHub repository structure
2. Build baseline GitHub Actions pipeline (no security tools — control condition)
3. Integrate Semgrep and capture first detection results

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

**Relevance to research:** First concrete data point for Metric 1 (Detection Capability — 20 findings, correctly identifying several of WebGoat's deliberately introduced weaknesses) and Metric 4 (Pipeline Overhead — 78 seconds for 974 files). The free-tier rule limitation (1,803 Pro rules unavailable without a paid account) is directly relevant to Metric 5 (Cost) and Metric 6 (SME Suitability).

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

**Next steps:**

1. Trufflehog integration (secret detection)
2. Falco integration (runtime anomaly detection)
3. OPA integration (policy enforcement)
4. Build baseline and open-source GitHub Actions pipelines


## 26th June 2026 — Trufflehog Integration (Tool 3 of 5)

**Objective:** Install Trufflehog and scan WebGoat's source code for hardcoded secrets and credentials, then supplement with a controlled test to generate a genuine detection-capability data point.

**Steps performed:**

1. Installed Trufflehog v3.95.6 via the official install script. Initial attempt failed with a permissions error (`cannot create regular file '/usr/local/bin/trufflehog': Permission denied`) — resolved by re-running with `sudo`.
2. First scan attempt failed with an updater error (`cannot move binary`) caused by Trufflehog's auto-update check attempting to write to a root-owned binary path. Resolved using the `--no-update` flag.
3. Ran `trufflehog filesystem . --no-update` against the WebGoat source tree.
4. An initial run produced misleading duplicate results because the scan's own output file was written into the directory being scanned and then re-scanned in the same pass. Resolved by directing output to `/tmp/` instead of inside the target directory.
5. Created a controlled test (`test-secrets-controlled/fake-credentials.env`) containing four deliberately injected fake secrets — an Azure Client Secret, an Azure Storage Connection String, a generic database password, and a GitHub personal access token — to directly measure detection capability, since WebGoat itself does not contain realistic hardcoded operational secrets.
6. Ran Trufflehog against the controlled test file.
7. Removed the controlled test file from the VM after scanning (`rm -rf test-secrets-controlled`).

**Result — WebGoat scan:** 2 findings (both unverified), both JWT tokens embedded in WebGoat's own JWT lesson documentation (`JWT.html`, `JWT_libraries.adoc`) — intentional teaching content, not leaked operational credentials. Scan covered 151.6 MB across 12,362 chunks in 41 seconds.

**Result — controlled test:** 1 of 4 (25%) injected fake secrets detected. The GitHub token was correctly identified (with a credential-rotation guide link returned). Neither the Azure Client Secret nor the Azure Storage Connection String were detected. The generic database password was not detected, as expected for unstructured secrets.

**Issues encountered:** Permissions error on install (resolved with `sudo`); auto-updater runtime error (resolved with `--no-update`); self-scan duplication on first WebGoat run (resolved by redirecting output outside the scan target).

**Full results and analysis:** `metrics/results/trufflehog-results.md`, raw output `metrics/results/trufflehog-findings-readable.txt` and `metrics/results/trufflehog-controlled-test.txt`

**Relevance to research:** The WebGoat scan result demonstrates that WebGoat is not, on its own, a sufficient test case for evaluating secret-detection tools, since its deliberate vulnerabilities are concentrated in code logic and dependency issues rather than hardcoded credentials — this is itself a useful methodological observation for the limitations section. The controlled test provides a genuine detection-capability data point (Metric 1): strong detection of well-known platform token formats (GitHub), no detection of the two Azure-specific credential formats tested, and no detection of unstructured secrets (an inherent limitation of pattern-based detection generally). The Azure detection gap is particularly significant given this project's cloud-native comparison stack is Azure-based, and is directly relevant to Metric 6 (SME Suitability) — an SME standardising on Azure may need to supplement Trufflehog with Azure-native secret scanning.

**Next steps:**

1. Falco integration (runtime anomaly detection)
2. OPA integration (policy enforcement)
3. Build baseline and open-source GitHub Actions pipelines



## 27th June 2026 (continued) — Falco Integration (Tool 4 of 5)

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

**Relevance to research:** Falco is methodologically distinct from the previous three tools in this stack — it detects anomalous behaviour in a *running* system rather than scanning static code, dependencies, or committed secrets. This demonstrates defence-in-depth across the software lifecycle but also means its "pipeline overhead" (Metric 4) isn't directly comparable to discrete scan durations; it is better characterised as continuous resource consumption (observed: ~46MB memory, ~48s CPU time over 13 minutes of monitoring — low overhead). Detection of the shell-spawn event required no custom rule configuration, demonstrating strong out-of-the-box capability for well-known anomaly patterns (Metric 1). The logging-destination friction point is directly relevant to Metric 3 (Setup Complexity) and Metric 6 (SME Suitability) — an SME team would need this knowledge before trusting the tool operationally.

**Next steps:**

1. OPA integration (policy enforcement) — final tool in the open-source stack
2. Build baseline and open-source GitHub Actions pipelines
3. Begin Azure cloud-native stack setup
