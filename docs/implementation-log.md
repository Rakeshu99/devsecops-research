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
| Network | NAT with port forwarding (SSH: 2222→22, WebGoat: 8080→8080, WebWolf: 9090→9090) |

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

| Component | Status |
|---|---|
| Ubuntu 24.04 VM (6GB RAM, 4 vCPU, 50GB disk) | Provisioned and operational |
| SSH remote access | Working |
| Docker Engine | Installed and verified |
| OWASP WebGoat | Deployed, accessible, user account created |

**Relevance to research:** This establishes the controlled test environment required for Phase 2 of the Design Science Research methodology (open-source stack construction and testing). The environment is now ready for the first security tool — Semgrep — to be integrated and run against WebGoat's source code as the first detection capability measurement (Metric 1).

**Next steps:**
1. Create GitHub repository structure
2. Build baseline GitHub Actions pipeline (no security tools — control condition)
3. Integrate Semgrep and capture first detection results
