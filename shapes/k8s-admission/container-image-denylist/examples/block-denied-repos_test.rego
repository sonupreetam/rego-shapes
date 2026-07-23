package k8s.block_denied_repos_test

import rego.v1

import data.k8s.block_denied_repos

test_denied_repo_blocked if {
	results := block_denied_repos.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"image": "docker.io/library/nginx:latest",
		}]}}},
		"parameters": {"repos": ["docker.io/"]},
	}
	count(results) == 1
}

test_allowed_repo_passes if {
	results := block_denied_repos.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"image": "registry.internal.io/nginx:v1",
		}]}}},
		"parameters": {"repos": ["docker.io/"]},
	}
	count(results) == 0
}

test_block_latest_tag if {
	results := block_denied_repos.violation with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"image": "evil.io/malware:latest",
		}]}}},
		"parameters": {"repos": ["evil.io/"]},
	}
	count(results) == 1
}

test_init_container_checked if {
	results := block_denied_repos.violation with input as {
		"review": {"object": {"spec": {
			"containers": [{"name": "app", "image": "registry.internal.io/app:v1"}],
			"initContainers": [{"name": "init", "image": "docker.io/busybox:latest"}],
		}}},
		"parameters": {"repos": ["docker.io/"]},
	}
	count(results) == 1
}
