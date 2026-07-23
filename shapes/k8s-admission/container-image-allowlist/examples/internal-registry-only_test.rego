package k8s.internal_registry_only_test

import rego.v1

import data.k8s.internal_registry_only

test_internal_image_allowed if {
	results := internal_registry_only.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"image": "registry.internal.io/myapp:v1",
		}]}}},
	}
	count(results) == 0
}

test_quay_org_allowed if {
	results := internal_registry_only.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"image": "quay.io/myorg/myapp:v1",
		}]}}},
	}
	count(results) == 0
}

test_public_image_denied if {
	results := internal_registry_only.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"image": "docker.io/library/nginx:latest",
		}]}}},
	}
	count(results) == 1
}

test_init_container_public_denied if {
	results := internal_registry_only.violation with input as {
		"review": {"object": {"spec": {
			"containers": [{"name": "app", "image": "registry.internal.io/app:v1"}],
			"initContainers": [{"name": "init", "image": "docker.io/busybox:latest"}],
		}}},
	}
	count(results) == 1
}
