# container-resource-limit-check

Check that container CPU or memory requests/limits do not exceed a parameter-supplied
maximum. Values are canonicalized (e.g., `"500m"` → 500 millicores, `"1Gi"` → bytes)
before comparison using shared helpers in `lib/resource_units.rego`.

## When to Use

- Enforce maximum CPU limits per container (`cpu ≤ 2`)
- Enforce maximum memory requests per container (`memory ≤ 1Gi`)
- Enforce maximum memory limits per container
- Enforce maximum CPU requests per container

## Runtime Dependency

This shape requires `lib/resource_units.rego` to be available at OPA evaluation time.
Deploy it alongside the generated policy:

```
my-policies/
├── lib/resource_units.rego    ← from rego-shapes/lib/
└── cpu-limit.rego             ← generated from this shape
```

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `Package` | string | ✅ | Rego package name |
| `ResourceType` | `"cpu"` \| `"memory"` | ✅ | Which resource to check |
| `Section` | `"limits"` \| `"requests"` | ✅ | Check limits or requests |

## Examples

### CPU limit enforcement

```
Package:      k8s.cpu_limit
ResourceType: cpu
Section:      limits
```

Denies containers with `resources.limits.cpu` exceeding `input.parameters.cpu`.

### Memory request enforcement

```
Package:      k8s.memory_request
ResourceType: memory
Section:      requests
```

Denies containers with `resources.requests.memory` exceeding `input.parameters.memory`.

## Corpus Coverage

Derived from 5 policies (10%) in
[gatekeeper-library](https://github.com/open-policy-agent/gatekeeper-library):

- `containerlimits` — CPU and memory limit enforcement
- `containerrequests` (from `containerresources`) — CPU and memory request enforcement
- `containerresourceratios` — limit-to-request ratio enforcement (partially covered)
- `ephemeralstoragelimit` — ephemeral storage limit (same structure, different resource)

## Pitfalls

1. **Missing `lib/resource_units.rego`** — If the library is not deployed alongside
   the policy, OPA will silently evaluate to no violations (undefined), not an error.
2. **Ratio checks** — The `containerresourceratios` policy checks limit-to-request
   *ratios*, which requires both limits and requests in the same rule. This shape
   only checks a single resource against a maximum. Ratio checks need a separate shape.
3. **Ephemeral storage** — Uses the same unit conversion logic but with
   `ephemeral-storage` as a hyphenated key. Extending `ResourceType` to support this
   would require bracket notation for the field access.

## Related Shapes

- `container-field-check` — for simple boolean/presence checks on container fields
- `container-field-in-allowlist` — for checking field values against an allowed set
