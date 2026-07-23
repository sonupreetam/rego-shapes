package k8s.require_team_label

import rego.v1

violation contains {"msg": msg, "details": {"missing_labels": missing}} if {
	provided := {key | some key, _ in input.review.object.metadata.labels}
	required := {"app", "team"}
	missing := required - provided
	count(missing) > 0
	msg := sprintf(
		"Resource '%s' is missing required labels: %v",
		[input.review.object.metadata.name, missing],
	)
}
