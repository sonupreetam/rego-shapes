# Kubernetes Manifest (Conftest/pre-deploy) — Shape Taxonomy

**Sources:**

| Repository | Policies | License |
|------------|----------|---------|
| [raspbernetes/k8s-security-policies](https://github.com/raspbernetes/k8s-security-policies) | 62 | Apache 2.0 |
| [conftest examples (kubernetes/)](https://github.com/open-policy-agent/conftest/tree/master/examples/kubernetes) | 12 | Apache 2.0 |
| [instrumenta/policies](https://github.com/instrumenta/policies) | ~30 | Apache 2.0 |
| [redhat-cop/rego-policies](https://github.com/redhat-cop/rego-policies) | ~30 | Apache 2.0 |

**Total policies analyzed:** ~134

## Input Shape

Policies operate on **raw Kubernetes manifests** (YAML parsed to JSON), as used by
Conftest for pre-deploy validation. The key difference from `k8s-admission` is the
input path:

| Aspect | k8s-admission (Gatekeeper) | k8s-manifest (Conftest) |
|--------|---------------------------|------------------------|
| Input root | `input.review.object` | `input` directly |
| Kind access | `input.review.object.kind` | `input.kind` |
| Spec access | `input.review.object.spec` | `input.spec` |
| Parameters | `input.parameters` | hardcoded or `data.*` |
| Rule head | `violation[{"msg": msg}]` | `deny contains msg` or `violation[msg]` |

Some libraries (raspbernetes, instrumenta) bridge both modes by normalizing to a
single `resource` variable. This means their shapes can work with either input mode.

## Shape Taxonomy

### From raspbernetes (62 policies)

| # | Shape | Policies | Coverage | Templateable |
|---|-------|----------|----------|:------------:|
| 1 | [component-flag-check](#1-component-flag-check) | 36 | 58% | ✅ |
| 2 | [container-field-check](#2-container-field-check) | 10 | 16% | ✅ |
| 3 | [pod-field-check](#3-pod-field-check) | 7 | 11% | ✅ |
| 4 | [rbac-rule-check](#4-rbac-rule-check) | 3 | 5% | ⚠️ |
| 5 | [resource-multi-field-check](#5-resource-multi-field-check) | 2 | 3% | ⚠️ |
| — | minor shapes (4 variants) | 4 | 6% | varies |

### From Conftest examples + instrumenta + redhat-cop

| # | Shape | Policies | Coverage | Templateable |
|---|-------|----------|----------|:------------:|
| 6 | [k8s-manifest-deny](#6-k8s-manifest-deny) | 12 | — | ✅ |
| 7 | [k8s-workload-violation](#7-k8s-workload-violation) | 30+ | — | ✅ |
| 8 | [flat-config-deny](#8-flat-config-deny) | 11 | — | ⚠️ |

---

### 1. component-flag-check

**Coverage:** 36 policies (58% of raspbernetes)

Checks CLI flags on Kubernetes control-plane components (kube-apiserver,
kube-controller-manager, kube-scheduler, etcd). Uses library helpers
`flag_contains_string` and `contains_element` to inspect `container.command`.

**Canonical structure:**

```rego
violation[msg] {
    kubernetes.apiserver[container]
    not kubernetes.flag_contains_string(container.command, "--<flag>", "<value>")
    msg := kubernetes.format(sprintf("API server: %s must be set to %s [%s]",
        [flag, value, kubernetes.name]))
}
```

**Four sub-variants by polarity:**

| Sub-variant | Condition | Count |
|-------------|-----------|------:|
| flag-value-required | `not flag_contains_string(cmd, key, val)` | 25 |
| flag-value-denied | `flag_contains_string(cmd, key, val)` | 5 |
| flag-must-exist | `not contains_element(cmd, key)` | 3 |
| flag-must-not-exist | `contains_element(cmd, key)` | 3 |

**Policies:** CIS.1.2.1–19, CIS.1.3.1–7, CIS.1.4.1–2, CIS.2.1–6, CIS.5.5.1

**Templateable:** ✅ — Parameters: component (apiserver|controller|scheduler|etcd),
flag name, expected value, polarity (required|denied|must-exist|must-not-exist),
CIS benchmark ID.

**This shape has no equivalent in the existing `k8s-admission` category.** It is
specific to CIS Kubernetes Benchmark auditing of control-plane manifests.

---

### 2. container-field-check

**Coverage:** 10 policies

Identical structure to the existing `k8s-admission/container-field-check` shape.
Iterates `containers[container]`, checks a field for truthiness/absence.

**Overlap:** ✅ Direct overlap with existing `k8s-admission/container-field-check`.
The library abstraction makes the same template usable for both input modes.

**Policies:** CIS.5.2.1, CIS.5.2.5, CIS.5.4.1, K.SEC.01–07, K.SEC.15

---

### 3. pod-field-check

**Coverage:** 7 policies

Checks a pod-level `spec` boolean field (hostPID, hostIPC, hostNetwork, hostAliases).
Uses `kubernetes.pods[pod]` iterator.

**Canonical structure:**

```rego
violation[msg] {
    kubernetes.pods[pod]
    pod.spec.hostNetwork
    msg := kubernetes.format(sprintf("%s: hostNetwork is not allowed [%s]",
        [kubernetes.kind, kubernetes.name]))
}
```

**Policies:** CIS.5.2.2–4, K.SEC.09, K.SEC.11, K.SEC.12, K.SEC.14

**Relationship to existing shapes:** Conceptually similar to
`resource-field-equality-block` but operates at pod level with boolean fields.
Could be modeled as a specialization.

**Templateable:** ✅ — Parameters: field path under `spec`, polarity
(must-be-true|must-be-false|must-not-exist).

---

### 4. rbac-rule-check

**Coverage:** 3 policies

Iterates RBAC resources (ClusterRoles, Roles, ClusterRoleBindings, RoleBindings)
and checks `rules[_]` fields or `roleRef`. Uses custom helper rules with set
intersection logic.

**Policies:** CIS.5.1.1 (cluster-admin binding), CIS.5.1.2 (secrets access),
CIS.5.1.3 (wildcard usage)

**Templateable:** ⚠️ — Each policy has unique set-intersection logic. Could
template the 2 common patterns (roleRef equality check, wildcard-in-verbs check)
but the secrets-access variant is complex.

---

### 5. resource-multi-field-check

**Coverage:** 2 policies

Multi-resource iteration (pods + serviceaccounts). Checks field equality with
allowlist logic.

**Policies:** CIS.5.1.5, CIS.5.1.6

**Templateable:** ⚠️ — Multi-resource correlation is hard to generalize.

---

### 6. k8s-manifest-deny

**Coverage:** 12 policies (Conftest K8s examples)

Raw K8s manifest policies using `deny contains msg` rule head. Input is direct
(`input.kind`, `input.spec`, `input.metadata`).

**Canonical structure:**

```rego
deny contains msg if {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext.runAsNonRoot
    msg := "Containers must not run as root"
}
```

**Templateable:** ✅ — Very simple structure. Parameters: kind, field path,
expected value, message.

---

### 7. k8s-workload-violation

**Coverage:** 30+ rules (instrumenta + redhat-cop)

Uses `violation[msg]` with a library that auto-detects Gatekeeper vs raw input.
Nearly all iterate `containers[container]` from a library helper.

**Overlap:** This is structurally equivalent to the existing `k8s-admission`
container shapes but with a dual-mode library. The shapes themselves (field-check,
allowlist, denylist) are the same — the library handles the input abstraction.

---

### 8. flat-config-deny

**Coverage:** 11 policies (Conftest examples)

Parsed application configs (INI, TOML, HOCON, .env, Compose, Nginx, VCL, etc.)
with `deny contains msg`. No `kind` discriminator — policies check specific key
paths directly.

**Templateable:** ⚠️ — The input shapes are too varied (each config format has
different structure). Individual templates per config format would be needed.

---

## Minor Shapes (1 policy each from raspbernetes)

| Shape | Policy | Description |
|-------|--------|-------------|
| container-numeric-check | K.SEC.08 | `runAsUser < 10000` |
| container-image-tag-check | K.SEC.10 | Image string parsing, tag == "latest" |
| volume-field-check | K.SEC.13 | `hostPath.path == "/var/run/docker.sock"` |
| component-flag-cross-value | CIS.2.7 | Two flag values must differ |

---

## Key Architectural Insight

The **input shape distinction** (Gatekeeper admission vs raw manifest) is less
important than it initially appears. Libraries like raspbernetes' `lib/kubernetes.rego`
and instrumenta's `lib/` completely abstract this away. This means:

1. Existing `k8s-admission` shapes (container-field-check, container-field-in-allowlist,
   etc.) are **directly reusable** for Conftest pre-deploy validation — the template
   just needs a different package name and rule head.

2. The truly **new** shapes from this corpus are:
   - `component-flag-check` (36 policies) — CIS benchmark control-plane auditing
   - `pod-field-check` (7 policies) — pod-level spec boolean checks

3. A shared `lib/kubernetes.rego` in rego-shapes would unlock dual-mode templates.
   This aligns with the library extraction approach already discussed for
   `container-resource-limit-check` (see `analysis/deferred.md`).

## Gate Assessment

| Criterion | Result |
|-----------|--------|
| ≥3 distinct shapes | ✅ 8 shapes across combined corpus |
| ≥3 shapes each covering ≥10 policies | ✅ component-flag-check (36), container-field-check (10), k8s-manifest-deny (12), k8s-workload-violation (30+) |
| From public sources | ✅ All Apache 2.0 |

**Shapes validated for the `k8s-manifest` category, but the overlap with
`k8s-admission` suggests a different organizational approach — see below.**

## Recommendation

Rather than creating a separate `k8s-manifest` category that duplicates
`k8s-admission` shapes with different rule heads, the better approach is:

1. **Add `component-flag-check`** to `k8s-admission/` (it's still K8s policy,
   just targeting control-plane manifests instead of workloads)
2. **Add `pod-field-check`** to `k8s-admission/` (sibling of `container-field-check`)
3. **Document the dual-mode pattern** — templates can note that the same shape
   works with both Gatekeeper and Conftest input by swapping the input accessor
4. **Defer `flat-config-deny`** — too input-varied to template cleanly
5. **Defer `rbac-rule-check`** — only 3 policies, each structurally unique

Priority for implementation:

1. **`component-flag-check`** — 36 policies, clean template surface, entirely new
2. **`pod-field-check`** — 7 policies, simple template, fills a gap
