package k8s.deny_privileged

import rego.v1

violation contains {"msg": msg} if {
	some container in input.review.object.spec.containers
	container.securityContext.privileged == true
	msg := sprintf(
		"Container '%s': privileged containers are not allowed",
		[container.name],
	)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.initContainers
	container.securityContext.privileged == true
	msg := sprintf(
		"Init container '%s': privileged containers are not allowed",
		[container.name],
	)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.ephemeralContainers
	container.securityContext.privileged == true
	msg := sprintf(
		"Ephemeral container '%s': privileged containers are not allowed",
		[container.name],
	)
}
