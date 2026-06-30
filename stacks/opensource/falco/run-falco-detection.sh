#!/bin/bash
# Falco runtime anomaly detection script — Open-Source Stack, Tool 4 of 5
# Starts Falco monitoring and triggers a test anomaly (shell in container)
#
# Usage: sudo ./run-falco-detection.sh
# Must be run as root or with sudo since Falco uses eBPF kernel probes
#
# Notes:
# - Falco logs to /var/log/syslog (syslog_output: enabled in /etc/falco/falco.yaml)
#   NOT to systemd journal unit 'falco' — use grep on syslog, not journalctl -u falco
# - Falco service starts automatically on boot (enabled via systemd)
# - Detection evidence: sudo tail -50 /var/log/syslog | grep -i falco

echo "=== Checking Falco service status ==="
sudo systemctl status falco --no-pager | head -10

echo ""
echo "=== Triggering test anomaly: spawning shell inside WebGoat container ==="
echo "Expected Falco rule: 'A shell was spawned in a container with an attached terminal'"
docker exec -it webgoat /bin/bash -c "whoami && echo 'Test anomaly complete'"

echo ""
echo "=== Collecting Falco detection results from syslog ==="
sleep 2
sudo tail -50 /var/log/syslog | grep -i falco > /tmp/falco-detection-results.txt
cat /tmp/falco-detection-results.txt

echo ""
echo "=== Detection results saved to /tmp/falco-detection-results.txt ==="
