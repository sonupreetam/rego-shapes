package k8s.block_latest_tag_test

import rego.v1

import data.k8s.block_latest_tag

test_latest_tag_blocked if {
	results := block_latest_tag.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"image": "registry.io/myapp:latest",
		}]}}},
		"parameters": {"tags": [":latest"]},
	}
	count(results) == 1
}

test_versioned_tag_allowed if {
	results := block_latest_tag.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"image": "registry.io/myapp:v1.2.3",
		}]}}},
		"parameters": {"tags": [":latest"]},
	}
	count(results) == 0
}

test_multiple_denied_tags if {
	results := block_latest_tag.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"image": "registry.io/myapp:dev",
		}]}}},
		"parameters": {"tags": [":latest", ":dev", ":staging"]},
	}
	count(results) == 1
}
