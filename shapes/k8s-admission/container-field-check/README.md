# container-field-check

Iterate over all containers in a pod spec and assert a condition on each one.

## When to Use

Use this shape when you need to check a single field or condition on every container
(including init and ephemeral containers) in a Kubernetes resource.

Common use cases:
- Block privileged containers
- Require `runAsNonRoot`
- Require `readOnlyRootFilesystem`
- Block `stdin`/`tty` access

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `Package` | string | Rego package name |
| `Condition` | string | Rego expression referencing `container` |
| `ViolationMessage` | string | Human-readable violation description |

## Example

```bash
Package:          "k8s.deny_privileged"
Condition:        "container.securityContext.privileged == true"
ViolationMessage: "privileged containers are not allowed"
```

## Pitfalls

- The condition is evaluated per container. If you need a pod-level check, use
  `pod-level-field-check` instead.
- Some fields may not exist on the container object. Use `not container.X` for
  existence checks or `object.get(container, "field", default)` for safe access.
- Ephemeral containers have a limited API surface — some fields don't apply.

## Covers

From gatekeeper-library: `allow-privilege-escalation`, `privileged-containers`,
`read-only-root-filesystem`, `host-probes-lifecycle`, `disallowinteractive`
