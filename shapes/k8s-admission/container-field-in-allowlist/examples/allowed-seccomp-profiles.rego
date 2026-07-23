package k8s.allowed_seccomp_profiles

import rego.v1

violation contains {"msg": msg} if {
	some container in input.review.object.spec.containers
	value := container.securityContext.seccompProfile.type
	not value_allowed(value)
	msg := sprintf(
		"Container '%s': seccompProfile type '%v' is not allowed. Allowed values: %v",
		[container.name, value, allowed_values],
	)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.initContainers
	value := container.securityContext.seccompProfile.type
	not value_allowed(value)
	msg := sprintf(
		"Init container '%s': seccompProfile type '%v' is not allowed. Allowed values: %v",
		[container.name, value, allowed_values],
	)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.ephemeralContainers
	value := container.securityContext.seccompProfile.type
	not value_allowed(value)
	msg := sprintf(
		"Ephemeral container '%s': seccompProfile type '%v' is not allowed. Allowed values: %v",
		[container.name, value, allowed_values],
	)
}

value_allowed(value) if {
	some allowed in allowed_values
	value == allowed
}

allowed_values := input.parameters.allowedProfiles
