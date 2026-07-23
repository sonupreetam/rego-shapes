# container-image-denylist

Block container images that match denied patterns (prefix, suffix, or contains).

## When to Use

Use this shape when you need to block images from specific registries or with specific
tags, using a parameter-supplied denylist.

Common use cases:
- Block images from untrusted registries (prefix match)
- Block `:latest` or `:dev` tags (suffix match)

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `Package` | string | Rego package name |
| `ParamKey` | string | Key in `input.parameters` holding the denylist |
| `MatchExpr` | string | Rego expression matching `image` against `denied` |

## Covers

From gatekeeper-library: `disallowedrepos`, `disallowedtags`
