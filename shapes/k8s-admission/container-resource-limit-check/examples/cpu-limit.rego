package k8s.cpu_limit

import rego.v1

import data.lib.resource_units

violation contains {"msg": msg} if {
	some container in input.review.object.spec.containers
	_check_resource(container)
	msg := _violation_msg(container)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.initContainers
	_check_resource(container)
	msg := _violation_msg(container)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.ephemeralContainers
	_check_resource(container)
	msg := _violation_msg(container)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.containers
	not container.resources.limits
	msg := sprintf("container <%v> has no resource limits", [container.name])
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.initContainers
	not container.resources.limits
	msg := sprintf("container <%v> has no resource limits", [container.name])
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.ephemeralContainers
	not container.resources.limits
	msg := sprintf("container <%v> has no resource limits", [container.name])
}

_check_resource(container) if {
	cpu_orig := container.resources.limits.cpu
	cpu := resource_units.canonify_cpu(cpu_orig)
	max_cpu := resource_units.canonify_cpu(input.parameters.cpu)
	cpu > max_cpu
}

_violation_msg(container) := msg if {
	msg := sprintf(
		"container <%v> cpu limits <%v> exceeds maximum <%v>",
		[container.name, container.resources.limits.cpu, input.parameters.cpu],
	)
}
