package k8s.block_nodeport

import rego.v1

violation contains {"msg": msg} if {
	input.review.kind.kind == "Service"
	input.review.object.spec.type == "NodePort"
	msg := sprintf(
		"Service '%s': NodePort services are not allowed",
		[input.review.object.metadata.name],
	)
}
