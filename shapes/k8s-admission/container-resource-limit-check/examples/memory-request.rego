package k8s.memory_request

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
	not container.resources.requests
	msg := sprintf("container <%v> has no resource requests", [container.name])
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.initContainers
	not container.resources.requests
	msg := sprintf("container <%v> has no resource requests", [container.name])
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.ephemeralContainers
	not container.resources.requests
	msg := sprintf("container <%v> has no resource requests", [container.name])
}

_check_resource(container) if {
	mem_orig := container.resources.requests.memory
	mem := resource_units.canonify_mem(mem_orig)
	max_mem := resource_units.canonify_mem(input.parameters.memory)
	mem > max_mem
}

_violation_msg(container) := msg if {
	msg := sprintf(
		"container <%v> memory requests <%v> exceeds maximum <%v>",
		[container.name, container.resources.requests.memory, input.parameters.memory],
	)
}
