# resource-numeric-range-check

Validate that a numeric field on a resource falls within parameter-supplied ranges.

## When to Use

Use this shape when a resource has a numeric field that must be within acceptable
bounds, and the bounds are supplied as policy parameters.

Common use cases:
- Enforce replica count limits on Deployments/StatefulSets
- Enforce HPA min/max replica ranges
- Enforce PDB minAvailable thresholds

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `Package` | string | Rego package name |
| `FieldPath` | string | Dot-separated path to the numeric field |
| `FieldName` | string | Human-readable name for messages |

The policy expects `input.parameters.ranges` as a list of `{min, max}` objects at
evaluation time.

## Covers

From gatekeeper-library: `replicalimits`, `horizontalpodautoscaler` (partial)
