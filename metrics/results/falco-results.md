# Falco Scan Results — Open-Source Stack, Tool 4 of 5

**Date:** 28 June 2026
**Tool:** Falco v0.44.1 (modern eBPF driver)
**Target:** Running `webgoat/webgoat` Docker container — live runtime behaviour monitoring

---

## Installation

**Command:**
```bash
curl -fsSL https://falco.org/repo/falcosecurity-packages.asc | sudo gpg --dearmor -o /usr/share/keyrings/falco-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/falco-archive-keyring.gpg] https://download.falco.org/packages/deb stable main" | sudo tee -a /etc/apt/sources.list.d/falcosecurity.list
sudo apt-get update -y
sudo apt-get install -y falco
```

Falco's installer automatically selected the **modern eBPF driver** (`falco-modern-bpf.service`) rather than a kernel module, which is the more portable and VM-friendly option — no kernel module build/load step required. Service confirmed active via `systemctl status falco`, monitoring syscalls across all CPUs with an 8MB ring buffer.

---

## Setup Issue and Resolution — Logging Destination Mismatch

**Issue:** `journalctl -u falco` returned no entries despite Falco's service being confirmed active and consuming CPU (process actively running).

**Root cause:** Falco's default configuration (`/etc/falco/falco.yaml`) has `syslog_output: enabled: true` and `log_syslog: true` — output is sent to `/var/log/syslog`, not tagged under the `falco` systemd unit in a way `journalctl -u falco` could filter. Falco was working correctly the entire time; the issue was purely about where to look for its output.

**Resolution:**
```bash
sudo tail -50 /var/log/syslog | grep -i falco
```

This is a genuine setup complexity finding worth noting: **Falco's default logging destination is not obvious from `systemctl status` alone**, and a user unfamiliar with this would reasonably (and incorrectly) conclude the tool wasn't generating alerts. This is directly relevant to Metric 3 (Setup Complexity) for SME evaluation — documentation/log location needs to be understood before alerts can be relied upon operationally.

---

## Detection Test — Shell Spawned in Container

**Test method:** Spawned an interactive shell inside the running WebGoat container (a common indicator of unauthorized container access or post-compromise activity):

```bash
docker exec -it webgoat /bin/bash
cat /etc/shadow   # denied — confirms container runs as non-root 'webgoat' user
whoami
exit
```

**Result: Detected successfully, twice (once per trigger).**

```
23:47:48.130705464: Notice A shell was spawned in a container with an attached terminal |
evt_type=execve user=webgoat user_uid=1001 process=bash proc_exepath=/usr/bin/bash
parent=containerd-shim command=bash container_id=4ecae51bbf66 container_name=webgoat
container_image_repository=webgoat/webgoat container_image_tag=latest
```

Falco correctly captured:
- The exact syscall event type (`execve`)
- The user inside the container (`webgoat`, uid 1001 — confirms non-root container execution)
- The process tree (`parent=containerd-shim`, `command=bash`)
- The container identity (ID, name, image, tag)

---

## Analysis

This is a genuinely different category of detection from the previous three tools:
- **Semgrep** — found issues in source code (static, pre-deployment)
- **Trivy** — found issues in dependencies/OS packages (static, pre-deployment)
- **Trufflehog** — found issues in committed secrets (static, pre-deployment)
- **Falco** — detects anomalous *behaviour* in a running system (dynamic, post-deployment)

Falco is the only tool in this stack operating at runtime rather than at the pre-pipeline/build stage. This is methodologically important: it demonstrates defence-in-depth across the software lifecycle, but also means Falco's "pipeline overhead" (Metric 4) is not directly comparable to the other three tools — it runs continuously rather than as a discrete scan with a start/end time, so its overhead is better characterised as ongoing resource consumption (CPU: ~48 seconds over 13 minutes of runtime; Memory: ~46MB) rather than a single scan duration.

Successful detection of the shell-spawn event with full container context (process tree, container identity, user) demonstrates strong out-of-the-box detection capability for a well-known, default-rule-covered anomaly pattern, with no custom rule configuration required.

---

## Relevance to Research Metrics

| Metric | Data Point |
|---|---|
| 1. Detection capability | Successfully detected interactive shell spawned in container — a default, out-of-the-box rule, with full forensic context (user, process tree, container identity) |
| 3. Setup complexity | Install straightforward via APT; default logging destination (syslog, not journald unit) was not obvious and required investigation — genuine friction point |
| 4. Pipeline overhead | Not a discrete scan — runs continuously. Resource consumption observed: ~46MB memory, ~48s CPU time over 13 minutes of monitoring (low overhead for continuous runtime protection) |
| 5. Cost | Free, fully open source |
| 6. SME suitability | Low resource footprint suitable for SME infrastructure; however, requires understanding of syslog-based alerting (or further configuration to route to a centralised destination) for practical day-to-day use — not "alert and forget" out of the box |
