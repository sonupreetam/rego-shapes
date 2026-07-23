package k8s.cpu_limit_test

import rego.v1

import data.k8s.cpu_limit

test_allowed_cpu_under_limit if {
	count(cpu_limit.violation) == 0 with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"resources": {"limits": {"cpu": "500m"}},
		}]}}},
		"parameters": {"cpu": "1"},
	}
}

test_denied_cpu_over_limit if {
	count(cpu_limit.violation) > 0 with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"resources": {"limits": {"cpu": "2"}},
		}]}}},
		"parameters": {"cpu": "1"},
	}
}

test_denied_cpu_missing_limits if {
	count(cpu_limit.violation) > 0 with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"resources": {},
		}]}}},
		"parameters": {"cpu": "1"},
	}
}

test_allowed_cpu_equal_to_limit if {
	count(cpu_limit.violation) == 0 with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"resources": {"limits": {"cpu": "1"}},
		}]}}},
		"parameters": {"cpu": "1"},
	}
}

test_denied_init_container_over_limit if {
	count(cpu_limit.violation) > 0 with input as {
		"review": {"object": {"spec": {
			"containers": [{
				"name": "app",
				"resources": {"limits": {"cpu": "500m"}},
			}],
			"initContainers": [{
				"name": "init",
				"resources": {"limits": {"cpu": "4"}},
			}],
		}}},
		"parameters": {"cpu": "2"},
	}
}

test_allowed_millicores_format if {
	count(cpu_limit.violation) == 0 with input as {
		"review": {"object": {"spec": {"containers": [{
			"name": "app",
			"resources": {"limits": {"cpu": "250m"}},
		}]}}},
		"parameters": {"cpu": "500m"},
	}
}
