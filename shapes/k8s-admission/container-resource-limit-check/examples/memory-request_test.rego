package k8s.memory_request_test

import rego.v1

import data.k8s.memory_request

test_allowed_memory_under_limit if {
	count(memory_request.violation) == 0 with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"resources": {"requests": {"memory": "128Mi"}},
		}]}}},
		"parameters": {"memory": "1Gi"},
	}
}

test_denied_memory_over_limit if {
	count(memory_request.violation) > 0 with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"resources": {"requests": {"memory": "2Gi"}},
		}]}}},
		"parameters": {"memory": "1Gi"},
	}
}

test_denied_memory_missing_requests if {
	count(memory_request.violation) > 0 with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"resources": {},
		}]}}},
		"parameters": {"memory": "1Gi"},
	}
}

test_allowed_memory_equal_to_limit if {
	count(memory_request.violation) == 0 with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"resources": {"requests": {"memory": "1Gi"}},
		}]}}},
		"parameters": {"memory": "1Gi"},
	}
}

test_denied_init_container_over_limit if {
	count(memory_request.violation) > 0 with input as {
		"review": {"object": {"spec": {
			"containers": [{
				"name": "app",
				"resources": {"requests": {"memory": "256Mi"}},
			}],
			"initContainers": [{
				"name": "init",
				"resources": {"requests": {"memory": "4Gi"}},
			}],
		}}},
		"parameters": {"memory": "2Gi"},
	}
}

test_allowed_ki_format if {
	count(memory_request.violation) == 0 with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"resources": {"requests": {"memory": "512Ki"}},
		}]}}},
		"parameters": {"memory": "1Mi"},
	}
}
