package k8s.deny_privileged_test

import rego.v1

import data.k8s.deny_privileged

test_privileged_denied if {
	results := deny_privileged.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "test",
			"securityContext": {"privileged": true},
		}]}}},
	}
	count(results) > 0
}

test_non_privileged_allowed if {
	results := deny_privileged.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "test",
			"securityContext": {"privileged": false},
		}]}}},
	}
	count(results) == 0
}

test_init_container_privileged_denied if {
	results := deny_privileged.violation with input as {
		"review": {"object": {"spec": {
			"containers": [{"name": "main", "securityContext": {"privileged": false}}],
			"initContainers": [{"name": "init", "securityContext": {"privileged": true}}],
		}}},
	}
	count(results) > 0
}

test_no_security_context_allowed if {
	results := deny_privileged.violation with input as {
		"review": {"object": {"spec": {"containers": [{"name": "test"}]}}},
	}
	count(results) == 0
}
