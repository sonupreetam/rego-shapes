# container-field-in-allowlist

Iterate over all containers and check that a field value is in a parameter-supplied
allowlist.

## When to Use

Use this shape when a container field must be one of a set of approved values, and the
approved values are supplied as policy parameters (not hardcoded).

Common use cases:
- Restrict allowed `procMount` types
- Restrict `seccompProfile.type` to approved profiles
- Restrict `seLinuxOptions.type`
- Restrict allowed capabilities

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `Package` | string | Rego package name |
| `ValueExpr` | string | Rego expression extracting the value from `container` |
| `FieldName` | string | Human-readable name for messages |
| `ParamKey` | string | Key in `input.parameters` holding the allowlist |

## Pitfalls

- The `ValueExpr` must resolve to a comparable value. Nested paths that don't exist
  will cause the rule body to be undefined (not a violation) — which may be the desired
  behavior (skip containers that don't set the field) or may need an additional
  existence check.
- For set-valued fields (like capabilities), use `container-field-check` with set
  operations instead.

## Covers

From gatekeeper-library: `apparmor`, `capabilities` (partial), `proc-mount`, `seccomp`,
`seccompv2`, `selinux` (partial), `flexvolume-drivers` (volume variant)
