package secretlogging
import rego.v1

deny contains msg if {
	some job_name, job in input.jobs
	some step in job.steps
	step.run
	contains(step.run, "echo")
	contains(step.run, "${{ secrets.")
	msg := sprintf("Job '%s' echoes a secret value directly to logs: %s", [job_name, step.run])
}
