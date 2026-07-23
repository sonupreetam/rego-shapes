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

---

## Appendix: Per-Policy Classification (raspbernetes)

Full structural classification of all 62 raspbernetes policies.

### CIS.1.2.x — API Server (19 policies → component-flag-check)

| Policy | Condition | Sub-variant |
|--------|-----------|-------------|
| CIS.1.2.1 | `not flag_contains_string(cmd, "--anonymous-auth", "false")` | flag-value-required |
| CIS.1.2.2 | `contains_element(cmd, "--token-auth-file")` | flag-must-not-exist |
| CIS.1.2.3 | `contains_element(cmd, "--DenyServiceExternalIPs")` | flag-must-not-exist |
| CIS.1.2.4 | `flag_contains_string(cmd, "--kubelet-https", "false")` | flag-value-denied |
| CIS.1.2.5 | `not contains_element(cmd, "--kubelet-client-certificate")` | flag-must-exist (×2) |
| CIS.1.2.6 | `not contains_element(cmd, "--kubelet-certificate-authority")` | flag-must-exist |
| CIS.1.2.7 | `flag_contains_string(cmd, "--authorization-mode", "AlwaysAllow")` | flag-value-denied |
| CIS.1.2.8 | `not flag_contains_string(cmd, "--authorization-mode", "Node")` | flag-value-required |
| CIS.1.2.9 | `not flag_contains_string(cmd, "--authorization-mode", "RBAC")` | flag-value-required |
| CIS.1.2.10 | `not flag_contains_string(cmd, "--enable-admission-plugins", "EventRateLimit")` | flag-value-required |
| CIS.1.2.11 | `flag_contains_string(cmd, "--enable-admission-plugins", "AlwaysAdmit")` | flag-value-denied |
| CIS.1.2.12 | `not flag_contains_string(cmd, "--enable-admission-plugins", "AlwaysPullImages")` | flag-value-required |
| CIS.1.2.13 | `not flag_contains_string(cmd, "--enable-admission-plugins", "SecurityContextDeny")` | flag-value-required |
| CIS.1.2.14 | `flag_contains_string(cmd, "--enable-admission-plugins", "NamespaceLifecycle")` | flag-value-denied |
| CIS.1.2.15 | `flag_contains_string(cmd, "--enable-admission-plugins", "NodeRestriction")` | flag-value-denied |
| CIS.1.2.16 | `not flag_contains_string(cmd, "--secure-port", "6443")` | flag-value-required |
| CIS.1.2.17 | `not flag_contains_string(cmd, "--profiling", "false")` | flag-value-required |
| CIS.1.2.18 | `contains_element(cmd, "--insecure-bind-address")` | flag-must-not-exist |
| CIS.1.2.19 | `not flag_contains_string(cmd, "--audit-log-path", ...)` | flag-value-required |

### CIS.1.3.x — Controller Manager (7 policies → component-flag-check)

| Policy | Flag | Sub-variant |
|--------|------|-------------|
| CIS.1.3.1 | `--terminated-pod-gc-threshold` | flag-value-required |
| CIS.1.3.2 | `--profiling=false` | flag-value-required |
| CIS.1.3.3 | `--use-service-account-credentials=true` | flag-value-required |
| CIS.1.3.4 | `--service-account-private-key-file` | flag-must-exist |
| CIS.1.3.5 | `--root-ca-file` | flag-must-exist |
| CIS.1.3.6 | `--feature-gates=RotateKubeletServerCertificate=true` | flag-value-required |
| CIS.1.3.7 | `--bind-address=127.0.0.1` | flag-value-required |

### CIS.1.4.x — Scheduler (2 policies → component-flag-check)

| Policy | Flag | Sub-variant |
|--------|------|-------------|
| CIS.1.4.1 | `--profiling=false` | flag-value-required |
| CIS.1.4.2 | `--bind-address=127.0.0.1` | flag-value-required |

### CIS.2.x — etcd (7 policies → component-flag-check)

| Policy | Flag | Sub-variant |
|--------|------|-------------|
| CIS.2.1 | `--cert-file` + `--key-file` | flag-value-required (×2 rules) |
| CIS.2.2 | `--client-cert-auth=true` | flag-value-required |
| CIS.2.3 | `--auto-tls=true` (deny) | flag-value-required |
| CIS.2.4 | `--peer-cert-file` + `--peer-key-file` | flag-value-required (×2 rules) |
| CIS.2.5 | `--peer-client-cert-auth=true` | flag-value-required |
| CIS.2.6 | `--peer-auto-tls=true` (deny) | flag-value-required |
| CIS.2.7 | `--trusted-ca-file` cross-value check | *(minor shape: cross-value)* |

### CIS.5.1.x — RBAC / Service Accounts (5 policies)

| Policy | Shape | Iteration | Condition |
|--------|-------|-----------|-----------|
| CIS.5.1.1 | rbac-rule-check | clusterrolebindings + rolebindings | `roleRef.name == "cluster-admin"` |
| CIS.5.1.2 | rbac-rule-check | clusterroles + roles | set intersection on rules |
| CIS.5.1.3 | rbac-rule-check | clusterroles + roles | `rules[_].*.* == "*"` |
| CIS.5.1.5 | resource-multi-field-check | pods + serviceaccounts | `serviceAccountName == "default"` |
| CIS.5.1.6 | resource-multi-field-check | pods + serviceaccounts | automountServiceAccountToken |

### CIS.5.2.x — Pod Security (5 policies)

| Policy | Shape | Field Checked |
|--------|-------|---------------|
| CIS.5.2.1 | container-field-check | `securityContext.privileged` |
| CIS.5.2.2 | pod-field-check | `spec.hostPID` |
| CIS.5.2.3 | pod-field-check | `spec.hostIPC` |
| CIS.5.2.4 | pod-field-check | `spec.hostNetwork` |
| CIS.5.2.5 | container-field-check | `securityContext.allowPrivilegeEscalation` |

### CIS.5.4.1, CIS.5.5.1

| Policy | Shape | Detail |
|--------|-------|--------|
| CIS.5.4.1 | container-field-check | `env[_].valueFrom.secretKeyRef` presence |
| CIS.5.5.1 | component-flag-check | apiserver `--enable-admission-plugins` |

### K.SEC.01–15 — Custom Security (15 policies)

| Policy | Shape | Field / Condition |
|--------|-------|-------------------|
| K.SEC.01 | container-field-check | `not resources.limits.cpu` |
| K.SEC.02 | container-field-check | `not resources.limits.memory` |
| K.SEC.03 | container-field-check | `capabilities.add[_] == cap` (set membership) |
| K.SEC.04 | container-field-check | `not dropped_capability(cap)` (negated set) |
| K.SEC.05 | container-field-check | `securityContext.privileged` |
| K.SEC.06 | container-field-check | `not readOnlyRootFilesystem` |
| K.SEC.07 | container-field-check | `not runAsNonRoot` |
| K.SEC.08 | *(minor: numeric-check)* | `runAsUser < 10000` |
| K.SEC.09 | pod-field-check | `spec.hostAliases` |
| K.SEC.10 | *(minor: image-tag-check)* | image tag == "latest" |
| K.SEC.11 | pod-field-check | `spec.hostNetwork` |
| K.SEC.12 | pod-field-check | `spec.hostIPC` |
| K.SEC.13 | *(minor: volume-field-check)* | `hostPath.path == "/var/run/docker.sock"` |
| K.SEC.14 | pod-field-check | `spec.hostPID` |
| K.SEC.15 | container-field-check | `securityContext.allowPrivilegeEscalation` |

### Shared Library (`lib/kubernetes.rego`)

All 62 policies import from `data.lib.kubernetes`. Key helpers:

| Helper | Used By |
|--------|---------|
| `kubernetes.containers[c]` | 10 policies (container-field-check) |
| `kubernetes.pods[pod]` | 7 policies (pod-field-check) |
| `kubernetes.apiserver[c]` | 19 policies (CIS.1.2.x) |
| `kubernetes.controller[c]` | 7 policies (CIS.1.3.x) |
| `kubernetes.scheduler[c]` | 2 policies (CIS.1.4.x) |
| `kubernetes.etcd[c]` | 7 policies (CIS.2.x) |
| `kubernetes.clusterroles[cr]` | 2 policies (CIS.5.1.x) |
| `kubernetes.rolebindings[rb]` | 1 policy (CIS.5.1.1) |
| `flag_contains_string(arr, key, val)` | 36 policies |
| `contains_element(arr, elem)` | 6 policies |
| `kubernetes.format(msg)` | All 62 policies |
