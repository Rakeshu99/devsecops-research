package githubactions

import rego.v1

# Deny rule: flags any 'run:' step that directly interpolates
# untrusted github context data without using an intermediate
# environment variable - the same risk class Semgrep flagged
# in WebGoat's release.yml (yaml.github-actions.security.run-shell-injection)

deny contains msg if {
	some job_name, job in input.jobs
	some step in job.steps
	step.run
	contains(step.run, "${{ github.")
	msg := sprintf("Job '%s' has a 'run' step using untrusted github context data directly: %s", [job_name, step.run])
}
