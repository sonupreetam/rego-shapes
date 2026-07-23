package k8s.replica_limits_test

import rego.v1

import data.k8s.replica_limits

test_within_range_allowed if {
	results := replica_limits.violation with input as {
		"review": {
			"kind": {"kind": "Deployment"},
			"object": {
				"metadata": {"name": "my-app"},
				"spec": {"replicas": 3},
			},
		},
		"parameters": {"ranges": [{"min": 1, "max": 10}]},
	}
	count(results) == 0
}

test_above_range_denied if {
	results := replica_limits.violation with input as {
		"review": {
			"kind": {"kind": "Deployment"},
			"object": {
				"metadata": {"name": "my-app"},
				"spec": {"replicas": 50},
			},
		},
		"parameters": {"ranges": [{"min": 1, "max": 10}]},
	}
	count(results) == 1
}

test_below_range_denied if {
	results := replica_limits.violation with input as {
		"review": {
			"kind": {"kind": "StatefulSet"},
			"object": {
				"metadata": {"name": "my-db"},
				"spec": {"replicas": 0},
			},
		},
		"parameters": {"ranges": [{"min": 1, "max": 5}]},
	}
	count(results) == 1
}

test_multiple_ranges if {
	results := replica_limits.violation with input as {
		"review": {
			"kind": {"kind": "Deployment"},
			"object": {
				"metadata": {"name": "my-app"},
				"spec": {"replicas": 3},
			},
		},
		"parameters": {"ranges": [{"min": 1, "max": 2}, {"min": 5, "max": 10}]},
	}
	count(results) == 1
}

test_exact_boundary_allowed if {
	results := replica_limits.violation with input as {
		"review": {
			"kind": {"kind": "Deployment"},
			"object": {
				"metadata": {"name": "my-app"},
				"spec": {"replicas": 5},
			},
		},
		"parameters": {"ranges": [{"min": 5, "max": 10}]},
	}
	count(results) == 0
}
