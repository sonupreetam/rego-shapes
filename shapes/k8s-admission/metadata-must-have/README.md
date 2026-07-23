# metadata-must-have

Require specific labels or annotations on a Kubernetes resource, with optional
regex validation of values.

## When to Use

Use this shape when you need to enforce that certain metadata keys exist and
optionally conform to a naming pattern.

Common use cases:
- Require `app`, `version`, `team` labels
- Require `owner` annotation with email format
- Require cost-center annotation matching `CC-\d{4}`

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `Package` | string | Rego package name |
| `MetadataType` | `labels` or `annotations` | Which metadata to check |
| `RequiredKeys` | string[] | List of required keys |
| `RegexChecks` | {Key, AllowedRegex}[] | Optional regex validation per key |

## Covers

From gatekeeper-library: `requiredlabels`, `requiredannotations`
