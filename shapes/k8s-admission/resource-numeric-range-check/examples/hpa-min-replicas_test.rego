package k8s.hpa_min_replicas_test

import rego.v1

import data.k8s.hpa_min_replicas

test_min_replicas_in_range if {
	results := hpa_min_replicas.violation with input as {
		"review": {
			"kind": {"kind": "HorizontalPodAutoscaler"},
			"object": {
				"metadata": {"name": "my-hpa"},
				"spec": {"minReplicas": 2},
			},
		},
		"parameters": {"ranges": [{"min": 2, "max": 10}]},
	}
	count(results) == 0
}

test_min_replicas_too_low if {
	results := hpa_min_replicas.violation with input as {
		"review": {
			"kind": {"kind": "HorizontalPodAutoscaler"},
			"object": {
				"metadata": {"name": "my-hpa"},
				"spec": {"minReplicas": 1},
			},
		},
		"parameters": {"ranges": [{"min": 2, "max": 10}]},
	}
	count(results) == 1
}
