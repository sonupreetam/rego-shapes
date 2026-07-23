# container-image-allowlist

Restrict container images to approved registries using prefix matching.

## When to Use

Use this shape when you need to enforce that all container images come from
a set of approved registries.

Common use cases:
- Restrict to internal registry only
- Allow only signed/verified registries
- Block public Docker Hub images

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `Package` | string | Rego package name |
| `AllowedRepos` | string[] | List of allowed image prefixes |

## Covers

From gatekeeper-library: `allowedrepos`, `allowedreposv2`
