package k8s.allowed_proc_mount_test

import rego.v1

import data.k8s.allowed_proc_mount

test_default_allowed if {
	results := allowed_proc_mount.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"securityContext": {"procMount": "Default"},
		}]}}},
		"parameters": {"allowedProcMountTypes": ["Default"]},
	}
	count(results) == 0
}

test_unmasked_denied if {
	results := allowed_proc_mount.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"securityContext": {"procMount": "Unmasked"},
		}]}}},
		"parameters": {"allowedProcMountTypes": ["Default"]},
	}
	count(results) == 1
}

test_no_proc_mount_skipped if {
	results := allowed_proc_mount.violation with input as {
		"review": {"object": {"spec": {"containers": [{"name": "app"}]}}},
		"parameters": {"allowedProcMountTypes": ["Default"]},
	}
	count(results) == 0
}
