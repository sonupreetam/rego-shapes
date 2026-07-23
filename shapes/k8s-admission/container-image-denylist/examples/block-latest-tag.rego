package k8s.block_latest_tag

import rego.v1

violation contains {"msg": msg} if {
	some container in input.review.object.spec.containers
	image := container.image
	some denied in input.parameters.tags
	endswith(image, denied)
	msg := sprintf(
		"Container '%s': image '%s' matches denied pattern '%s'",
		[container.name, image, denied],
	)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.initContainers
	image := container.image
	some denied in input.parameters.tags
	endswith(image, denied)
	msg := sprintf(
		"Init container '%s': image '%s' matches denied pattern '%s'",
		[container.name, image, denied],
	)
}

violation contains {"msg": msg} if {
	some container in input.review.object.spec.ephemeralContainers
	image := container.image
	some denied in input.parameters.tags
	endswith(image, denied)
	msg := sprintf(
		"Ephemeral container '%s': image '%s' matches denied pattern '%s'",
		[container.name, image, denied],
	)
}
