package k8s.require_team_label_test

import rego.v1

import data.k8s.require_team_label

test_both_labels_present_allowed if {
	results := require_team_label.violation with input as {
		"review": {"object": {"metadata": {
			"name": "my-pod",
			"labels": {"app": "web", "team": "platform"},
		}}},
	}
	count(results) == 0
}

test_missing_team_denied if {
	results := require_team_label.violation with input as {
		"review": {"object": {"metadata": {
			"name": "my-pod",
			"labels": {"app": "web"},
		}}},
	}
	count(results) == 1
}

test_no_labels_denied if {
	results := require_team_label.violation with input as {
		"review": {"object": {"metadata": {"name": "my-pod"}}},
	}
	count(results) == 1
}
