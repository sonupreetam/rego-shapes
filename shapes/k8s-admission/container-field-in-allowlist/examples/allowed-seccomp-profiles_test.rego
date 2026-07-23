package k8s.allowed_seccomp_profiles_test

import rego.v1

import data.k8s.allowed_seccomp_profiles

test_runtime_default_allowed if {
	results := allowed_seccomp_profiles.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"securityContext": {"seccompProfile": {"type": "RuntimeDefault"}},
		}]}}},
		"parameters": {"allowedProfiles": ["RuntimeDefault", "Localhost"]},
	}
	count(results) == 0
}

test_unconfined_denied if {
	results := allowed_seccomp_profiles.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"securityContext": {"seccompProfile": {"type": "Unconfined"}},
		}]}}},
		"parameters": {"allowedProfiles": ["RuntimeDefault", "Localhost"]},
	}
	count(results) == 1
}

test_no_seccomp_profile_skipped if {
	results := allowed_seccomp_profiles.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"securityContext": {},
		}]}}},
		"parameters": {"allowedProfiles": ["RuntimeDefault"]},
	}
	count(results) == 0
}

test_init_container_checked if {
	results := allowed_seccomp_profiles.violation with input as {
		"review": {"object": {"spec": {
			"containers": [{"name": "app", "securityContext": {"seccompProfile": {"type": "RuntimeDefault"}}}],
			"initContainers": [{"name": "init", "securityContext": {"seccompProfile": {"type": "Unconfined"}}}],
		}}},
		"parameters": {"allowedProfiles": ["RuntimeDefault"]},
	}
	count(results) == 1
}
