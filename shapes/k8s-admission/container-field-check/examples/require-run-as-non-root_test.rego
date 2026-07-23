package k8s.require_run_as_non_root_test

import rego.v1

import data.k8s.require_run_as_non_root

test_run_as_non_root_true_allowed if {
	results := require_run_as_non_root.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "test",
			"securityContext": {"runAsNonRoot": true},
		}]}}},
	}
	count(results) == 0
}

test_run_as_non_root_false_denied if {
	results := require_run_as_non_root.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "test",
			"securityContext": {"runAsNonRoot": false},
		}]}}},
	}
	count(results) > 0
}

test_missing_run_as_non_root_denied if {
	results := require_run_as_non_root.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "test",
			"securityContext": {},
		}]}}},
	}
	count(results) > 0
}
