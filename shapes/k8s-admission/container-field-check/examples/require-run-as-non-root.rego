package k8s.require_run_as_non_root

import rego.v1

violation contains {"msg": msg} if {
	some container in input.review.object.spec.containers
	not container.securityContext.runAsNonRoot == true
	msg := sprintf(
		"Container '%s': must set runAsNonRoot to true",
		[container.name],
	)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.initContainers
	not container.securityContext.runAsNonRoot == true
	msg := sprintf(
		"Init container '%s': must set runAsNonRoot to true",
		[container.name],
	)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.ephemeralContainers
	not container.securityContext.runAsNonRoot == true
	msg := sprintf(
		"Ephemeral container '%s': must set runAsNonRoot to true",
		[container.name],
	)
}
