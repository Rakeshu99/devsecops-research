package actionpinning
import rego.v1

deny contains msg if {
	some job_name, job in input.jobs
	some step in job.steps
	step.uses
	not regex.match(`@[0-9a-f]{40}$`, step.uses)
	not startswith(step.uses, "actions/")
	not startswith(step.uses, "./")
	msg := sprintf("Job '%s' uses unpinned third-party action: %s", [job_name, step.uses])
}
