package k8s.block_nodeport_test

import rego.v1

import data.k8s.block_nodeport

test_nodeport_denied if {
	results := block_nodeport.violation with input as {
		"review": {
			"kind": {"kind": "Service"},
			"object": {
				"metadata": {"name": "my-svc"},
				"spec": {"type": "NodePort"},
			},
		},
	}
	count(results) == 1
}

test_clusterip_allowed if {
	results := block_nodeport.violation with input as {
		"review": {
			"kind": {"kind": "Service"},
			"object": {
				"metadata": {"name": "my-svc"},
				"spec": {"type": "ClusterIP"},
			},
		},
	}
	count(results) == 0
}

test_non_service_ignored if {
	results := block_nodeport.violation with input as {
		"review": {
			"kind": {"kind": "Deployment"},
			"object": {
				"metadata": {"name": "my-deploy"},
				"spec": {"type": "NodePort"},
			},
		},
	}
	count(results) == 0
}
