package k8s.replica_limits

import rego.v1

violation contains {"msg": msg} if {
	value := input.review.object.spec.replicas
	not value_in_range(value)
	msg := sprintf(
		"%s '%s': replica count %d is outside allowed ranges %v",
		[input.review.kind.kind, input.review.object.metadata.name, value, input.parameters.ranges],
	)
}

value_in_range(value) if {
	some range in input.parameters.ranges
	range.min <= value
	range.max >= value
}
