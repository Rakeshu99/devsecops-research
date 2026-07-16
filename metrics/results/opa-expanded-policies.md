## Expanded OPA Policy Test Set — 2 Additional Policies

Added to broaden false-positive-rate evidence beyond the single existing
shell-injection policy, covering two additional CI/CD risk classes from the
OWASP Top 10 CI/CD Security Risks framework already cited in this study's
motivation.

---

### Policy 2 — Unpinned Third-Party GitHub Actions (OWASP CICD-SEC-3: Dependency Chain Abuse)

Third-party GitHub Actions referenced by a mutable tag (`@main`, `@latest`,
`@v1`) rather than a pinned commit SHA are vulnerable to supply-chain
compromise: if the action's maintainer's account is compromised, the next
workflow run silently pulls malicious code with no version change to alert
the pipeline owner.

**Policy logic** (`stacks/opensource/opa/action-pinning.rego`):
```rego
package actionpinning
import rego.v1

deny contains msg if {
	some job_name, job in input.jobs
	some step in job.steps
	step.uses
	not regex.match(`@[0-9a-f]{40}$`, step.uses)
	not startswith(step.uses, "actions/")
	msg := sprintf("Job '%s' uses unpinned third-party action: %s", [job_name, step.uses])
}
```

Note: `actions/*` (GitHub's own first-party actions) are excluded from this
check, since they carry a materially different trust boundary than
third-party marketplace actions — a deliberate scope decision, not an
oversight.

**Test 1 — True Positive**
Input: a workflow step using `uses: some-third-party/action@v1` (mutable tag).
Expected: policy denies, citing the unpinned reference.

**Test 2 — True Negative**
Input: a workflow step using `uses: some-third-party/action@a1b2c3...` (40-character pinned SHA).
Expected: no denial.

---

### Policy 3 — Secrets Echoed to Logs (OWASP CICD-SEC-6: Insufficient Credential Hygiene)

A workflow step that echoes a `secrets.*` context value directly (e.g. for
debugging) writes the secret value into the plaintext build log, which is
often retained and sometimes readable by a wider audience than the secret
itself.

**Policy logic** (`stacks/opensource/opa/secret-logging.rego`):
```rego
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
```

**Test 1 — True Positive**
Input: a step with `run: echo "${{ secrets.API_KEY }}"`.
Expected: policy denies.

**Test 2 — True Negative**
Input: a step with `run: echo "Build complete"` (no secret reference) and a
separate step correctly using `env: API_KEY: ${{ secrets.API_KEY }}` without
echoing it.
Expected: no denial.

---

## Updated False Positive Rate evidence base

| Policy | True Positive | True Negative | Risk class |
|---|---|---|---|
| Shell injection (existing) | Confirmed | Confirmed | CICD-SEC-1: Insufficient Flow Control |
| Action pinning (new) | Confirmed | Confirmed | CICD-SEC-3: Dependency Chain Abuse |
| Secret logging (new) | Confirmed | Confirmed | CICD-SEC-6: Insufficient Credential Hygiene |

Three independent policy/test-case pairs across three distinct CI/CD risk
classes, each with a matched true-positive and true-negative case, gives six
total ground-truth data points instead of two — a threefold increase in the
False Positive Rate evidence base, and broader coverage across the OWASP
CI/CD risk taxonomy rather than repeated testing of a single risk class.

---

## Real-world validation (CI-integrated, against WebGoat's actual workflows)

Beyond the synthetic true-positive/true-negative test cases above, both new
policies — and a corrected version of Policy 1 — were run against WebGoat's
actual GitHub Actions workflows (`release.yml`, `build.yml`), the same real
target used for the original shell-injection policy's true-positive finding.

**Note:** the CI-integrated version of Policy 1 was previously misconfigured
to evaluate this project's own `opensource-stack.yml` rather than WebGoat's
`release.yml`, which would have silently returned an empty (false) result on
every automated run despite the correct manual finding being documented.
This was caught during CI integration of the two new policies and corrected
— all three policies now correctly target WebGoat's real workflow files in
the automated pipeline, matching the manually-verified methodology.

**Policy 1 (shell injection) vs. real `release.yml`:** 1 finding confirmed —
untrusted `github.ref_name` context used directly in a shell `run` step,
matching the original manually-documented finding.

**Policy 2 (action pinning) vs. real `release.yml` + `build.yml`:** 9
findings confirmed — `docker/build-push-action@v7.2.0`,
`docker/login-action@v4.2.0`, `docker/setup-buildx-action@v4`,
`docker/setup-qemu-action@v4.1.0`, `softprops/action-gh-release@v3`,
`devops-infra/action-commit-push@v1.5.0`,
`devops-infra/action-pull-request@v1.3.0`, `pre-commit-ci/lite-action@v1.1.0`,
`pre-commit/action@v3.0.1` — all referenced by mutable version tag rather
than a pinned commit SHA.

An initial version of this policy also flagged WebGoat's own local composite
action (`./.github/actions/java-setup`) as unpinned third-party — a false
positive, since relative-path local actions carry no supply-chain risk and
are not third-party. The policy was corrected to exclude `./`-prefixed
references, alongside the existing `actions/`-prefix exclusion for GitHub's
own first-party actions. This correction is itself retained as evidence for
the False Positive Rate discussion: a policy-as-code rule, like a scanner
signature, requires its own verification against real-world input before its
output can be trusted.

**Policy 3 (secret logging) vs. real `release.yml`:** 0 findings — correctly
confirms WebGoat's actual release workflow does not echo secret values to
logs, a genuine true-negative result against real-world code rather than a
synthetic control case.

This real-world validation strengthens the False Positive Rate evidence base
beyond the six synthetic ground-truth data points: all three policies now
also have at least one confirmed result against actual, unmodified
third-party code, not only constructed test fixtures.
