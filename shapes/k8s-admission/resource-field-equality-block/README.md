# resource-field-equality-block

Block a Kubernetes resource when a field equals a specific forbidden value.

## When to Use

Use this shape for simple, single-field blocking rules with no container iteration.

Common use cases:
- Block NodePort services
- Block LoadBalancer services
- Block hostNetwork pods

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `Package` | string | Rego package name |
| `Kind` | string | Kubernetes resource kind |
| `FieldPath` | string | Dot-separated field path on the resource |
| `BlockedValue` | string | Value to deny |
| `ViolationMessage` | string | Human-readable violation description |

## Covers

From gatekeeper-library: `block-loadbalancer-services`, `block-nodeport-services`
