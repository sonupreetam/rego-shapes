# Rego Shape Taxonomy

Derived from structural analysis of 49 policies in [gatekeeper-library](https://github.com/open-policy-agent/gatekeeper-library).

## Methodology

Each policy was classified by **structural shape** — how the Rego code is shaped — not by
what compliance check it performs. Two policies checking different things but sharing the
same Rego structure belong to the same shape.

Five structural questions were answered per policy:

1. How many `input.*` paths are accessed?
2. Is there iteration? Over what?
3. What's the rule head shape?
4. How is the violation condition expressed?
5. Are there helper rules or data references?

## Combined Shape Taxonomy

| # | Shape | Policies | Coverage | Templateable |
|---|-------|----------|----------|:------------:|
| 1 | [container-field-in-allowlist](#1-container-field-in-allowlist) | 7 | 14% | ✅ |
| 2 | [container-resource-limit-check](#2-container-resource-limit-check) | 5 | 10% | ⚠️ |
| 3 | [container-field-check](#3-container-field-check) | 5 | 10% | ✅ |
| 4 | [container-image-allowlist](#4-container-image-allowlist) | 2 | 4% | ✅ |
| 5 | [container-image-denylist](#5-container-image-denylist) | 2 | 4% | ✅ |
| 6 | [metadata-must-have-with-regex](#6-metadata-must-have-with-regex) | 2 | 4% | ✅ |
| 7 | [resource-field-equality-block](#7-resource-field-equality-block) | 2 | 4% | ✅ |
| 8 | [resource-numeric-range-check](#8-resource-numeric-range-check) | 2 | 4% | ✅ |
| 9 | [cross-resource-uniqueness-check](#9-cross-resource-uniqueness-check) | 2 | 4% | ⚠️ |
| 10 | [cross-resource-consistency-check](#10-cross-resource-consistency-check) | 2 | 4% | ⚠️ |
| 11 | [pod-and-container-field-check](#11-pod-and-container-field-check) | 2 | 4% | ✅ |
| 12 | [resource-field-pattern-block](#12-resource-field-pattern-block) | 2 | 4% | ⚠️ |
| 13 | [volume-field-in-allowlist](#13-volume-field-in-allowlist) | 2 | 4% | ✅ |
| — | Singletons (7 unique shapes) | 12 | 24% | varies |

**Total: 49 policies → 20 shapes. Top 6 shapes cover 43% of all policies.**

### Templateability Legend

- ✅ = Shape has clear, regular structure suitable for `text/template`
- ⚠️ = Shape has complex helpers or heavy logic that limits parameterization

---

## Shape Details

### 1. container-field-in-allowlist

**Structure:** Iterate over all containers (containers, initContainers, ephemeralContainers),
check a field value against a parameter-supplied list.

**Policies:** `apparmor`, `capabilities`, `proc-mount`, `seccomp`, `seccompv2`,
`allowedrepos` (image prefix), `disallowedrepos` (inverted)

**Parameters:**
- `field_path` — the container field to check
- `allowed_values` — list of permitted values
- `match_type` — exact, prefix, or glob

**Variation:** Some check `securityContext.X`, others check `image`, others check annotation keys.
The core shape is the same: iterate containers, match field against list.

---

### 2. container-resource-limit-check

**Structure:** Iterate containers, validate that resource requests/limits exist and fall
within numeric bounds. Includes unit canonicalization helpers (CPU, memory, storage).

**Policies:** `containerlimits`, `containerrequests`, `containerresourceratios`,
`containerresources`, `ephemeralstoragelimit`

**Parameters:**
- `resource_type` — cpu, memory, ephemeral-storage
- `field` — limits, requests, or both
- `max_value` / `min_value` — numeric bounds

**Note:** Heavy helper rule boilerplate (canonify_cpu, canonify_mem, mem_multiple, get_suffix).
These 5 policies share nearly identical conversion code — prime target for library extraction
but harder to reduce to a simple template.

---

### 3. container-field-check

**Structure:** Iterate containers, assert a boolean or existence condition on a
`securityContext` field. No parameters — the check is hardcoded.

**Policies:** `allow-privilege-escalation`, `host-probes-lifecycle`,
`privileged-containers`, `read-only-root-filesystem`, `disallowinteractive`

**Parameters:**
- `field_path` — the container field to check (e.g., `securityContext.allowPrivilegeEscalation`)
- `expected_value` — the required value (e.g., `false`, `true`)
- `operator` — equality, negation, existence

**Note:** Despite having no parameters in the original policies, these are trivially
parameterizable because the only thing that varies is which field is checked.

---

### 4. container-image-allowlist

**Structure:** Iterate containers, check that image matches an allowed registry/pattern list.

**Policies:** `allowedrepos`, `allowedreposv2`

**Parameters:**
- `allowed_repos` — list of permitted image prefixes/patterns
- `match_type` — prefix, exact, or glob

---

### 5. container-image-denylist

**Structure:** Iterate containers, check that image does NOT match a blocked pattern list.

**Policies:** `disallowedrepos`, `disallowedtags`

**Parameters:**
- `denied_patterns` — list of blocked prefixes/tags
- `match_type` — prefix or suffix

---

### 6. metadata-must-have-with-regex

**Structure:** Check that required labels/annotations exist on the object metadata, with
optional regex validation of values.

**Policies:** `requiredannotations`, `requiredlabels`

**Parameters:**
- `metadata_type` — `labels` or `annotations`
- `required_keys` — list of `{key, allowedRegex}` pairs

---

### 7. resource-field-equality-block

**Structure:** Simple field equality check on the resource — no iteration, no containers.
Block a resource if a field equals a forbidden value.

**Policies:** `block-loadbalancer-services`, `block-nodeport-services`

**Parameters:**
- `kind` — resource kind to match (e.g., `Service`)
- `field_path` — the field to check
- `blocked_value` — value to deny

---

### 8. resource-numeric-range-check

**Structure:** Check that a numeric field on the resource falls within an allowed range.

**Policies:** `horizontalpodautoscaler`, `replicalimits`

**Parameters:**
- `field_path` — numeric field (e.g., `spec.replicas`)
- `ranges` — list of `{min, max}` pairs

---

### 9. cross-resource-uniqueness-check

**Structure:** Compare the admitted resource against other resources in the cluster
(via `data.inventory`) to ensure a field value is unique.

**Policies:** `uniqueingresshost`, `uniqueserviceselector`

**Parameters:**
- `resource_kind` — what to compare against
- `field_path` — field that must be unique

**Note:** Requires `data.inventory` — only works with Gatekeeper's sync mechanism.

---

### 10. cross-resource-consistency-check

**Structure:** Cross-reference the admitted resource against related resources in the
cluster to verify consistency (e.g., PDB matches deployment replicas).

**Policies:** `poddisruptionbudget`, `storageclass`

**Note:** Highly domain-specific. Hard to generalize into a single template.

---

### 11. pod-and-container-field-check

**Structure:** Check a field at both pod-spec level AND container level. Common for
security context fields that can be set at either scope.

**Policies:** `host-network-ports`, `host-process`

**Parameters:**
- `pod_field_path` — pod-level field (e.g., `spec.hostNetwork`)
- `container_field_path` — container-level field (e.g., `securityContext.windowsOptions.hostProcess`)

---

### 12. resource-field-pattern-block

**Structure:** Check a field against a pattern (regex, string contains, prefix) rather
than exact equality.

**Policies:** `block-wildcard-ingress`, `httpsonly`

**Note:** Variable enough that a single template may not cover both cases cleanly.

---

### 13. volume-field-in-allowlist

**Structure:** Iterate over volumes or volume mounts, check field values against an
allowed list.

**Policies:** `flexvolume-drivers`, `host-filesystem`

**Parameters:**
- `volume_field` — which volume field to check
- `allowed_values` — list of permitted values

---

## Singleton Shapes (1 policy each)

| Shape | Policy | Why it's unique |
|-------|--------|-----------------|
| container-image-format-check | `imagedigests` | Regex on image format, not against a list |
| container-field-must-exist | `requiredprobes` | Checks existence of probe fields, not values |
| pod-field-boolean-check | `automount-serviceaccount-token` | Pod-level only, no container iteration |
| field-in-allowlist | `externalip` | Set difference on spec field, not container |
| volume-type-allowlist | `volumes` | Checks volume type names, not field values |
| pod-level-numeric-range-check | `fsgroup` | Numeric range on pod-level field |
| pod-level-list-against-denylist | `forbidden-sysctls` | Glob match on sysctl names |
| rbac-rule-check | `block-endpoint-edit-default-role` | RBAC-specific structure |
| rbac-subject-check | `disallowanonymous` | RBAC subject iteration |
| update-mutation-guard | `noupdateserviceaccount` | Operation-gated field comparison |
| api-version-check | `verifydeprecatedapi` | API version enumeration |

---

## Key Statistics

- **Container iteration** is the dominant pattern: 35/49 policies (71%)
- **Parameter-driven** policies: 35/49 (71%) reference `input.parameters.*`
- **Inventory-dependent** policies: 10/49 (20%) reference `data.inventory.*` or `data.lib.*`
- **Rule head variants**: 40 use `violation[{"msg": msg}]`, 9 include `"details"` field
- **Top 6 shapes cover 43%** of all policies — these are the priority for templates
- **80% coverage** is achievable with the top 13 shapes (non-singleton shapes)
