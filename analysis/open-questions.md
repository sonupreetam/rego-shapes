# Open Questions

Unresolved design questions from corpus analysis and implementation. Each entry
needs a decision before the related shape or category can proceed.

---

## Terraform Plan shapes

### OQ-1: Merge `tf-inline-flat-deny` into `tf-resource-field-check`?

**Context:** `tf-inline-flat-deny` (~10 policies) is structurally a compact version
of `tf-resource-field-check` (~45 policies) — same iteration, same condition types,
but no extracted helper rules. Everything is inlined in the `deny[reason]` body.

**Options:**

| Option | Trade-off |
|--------|-----------|
| **One template with a `Compact` boolean parameter** | Fewer shapes to maintain. Template has conditional `{{if .Compact}}` branching, making it harder to read. |
| **Two separate shapes** | Clear separation. Each template is simple. But they're 90% identical, so bug fixes must be applied twice. |
| **Only ship `tf-resource-field-check`** | Drop the compact variant entirely. The 10 inline policies can still be generated from the full template — the helpers just add a few lines. |

**Decision:** Not yet made.

### OQ-2: `tf-config-reference-check` needs a shared library

**Context:** 18 policies need `find_configuration_resource` to resolve Terraform
config expressions/references. This is analogous to `lib/resource_units.rego` — a
substantial helper (~40 lines) reused across multiple policies.

**Options:**

| Option | Trade-off |
|--------|-----------|
| **Add `lib/tf_utils.rego`** | Follows the `lib/` pattern established for resource units. Consumers deploying Terraform plan policies would need both the shape output and `lib/tf_utils.rego`. |
| **Inline `find_configuration_resource` in the template** | Self-contained output but 40+ lines of fixed helpers per policy. |
| **Defer `tf-config-reference-check` entirely** | Ship the 3 simpler shapes first. Come back to this when the `lib/` pattern is more mature. |

**Decision:** Not yet made. Leaning toward defer — ship shapes 1, 3, 4 first.

### OQ-3: `data.utils` dependency in Terraform templates

**Context:** 86% of the AWS corpus imports `data.utils` for `is_create_or_update`
and `contains_element`. Should rego-shapes templates assume these utils exist, or
should shapes inline the logic?

**Options:**

| Option | Trade-off |
|--------|-----------|
| **Add `lib/tf_utils.rego` with `is_create_or_update`** | Matches how the source corpus works. Consumers need to deploy it. |
| **Inline the action check** | `resource.change.actions[_] == "create"` is 2 lines — simple enough to inline without a library. |

**Decision:** Not yet made. The action check is simple enough to inline.

---

## Kubernetes Manifest shapes

### OQ-4: `component-flag-check` needs flag-parsing helpers

**Context:** The raspbernetes corpus uses `flag_contains_string`, `contains_element`,
and `value_by_key` from `lib/kubernetes.rego` to parse CLI flags on control-plane
containers. These are ~30 lines of helpers.

**Options:**

| Option | Trade-off |
|--------|-----------|
| **Add `lib/k8s_flags.rego`** | Clean separation. Follows established `lib/` pattern. |
| **Inline flag helpers in the template** | ~30 lines of helpers per policy. Acceptable for self-contained shapes but duplicated across 36 policies. |
| **Full `lib/kubernetes.rego` (dual-mode input)** | Most complete — handles both Gatekeeper and Conftest input. But it's ~80 lines and pulls in more than flag parsing. Scope creep risk. |

**Decision:** Not yet made. Need to decide whether to ship just flag helpers or the
full dual-mode library.

### OQ-5: Should `pod-field-check` be a specialization of `resource-field-equality-block`?

**Context:** `pod-field-check` (7 policies) checks pod-level `spec` boolean fields
(hostPID, hostIPC, hostNetwork). This is structurally similar to
`resource-field-equality-block` but uses pod-specific iteration.

**Options:**

| Option | Trade-off |
|--------|-----------|
| **New shape `pod-field-check`** | Clear, focused. But similar to an existing shape. |
| **Extend `resource-field-equality-block`** | Add a parameter for iteration target (pod vs generic resource). More general but more complex template. |

**Decision:** Not yet made. Leaning toward a new shape — the pod iteration pattern
is distinct enough.

### OQ-6: Do we need a `k8s-manifest` category at all?

**Context:** The k8s-manifest taxonomy found that most shapes overlap with existing
`k8s-admission` shapes. The recommendation is to fold new shapes into `k8s-admission/`
rather than creating a separate category. But the `k8s-manifest-deny` shape (12
Conftest policies, `deny contains msg`) uses a different rule head and direct input —
it doesn't fit `k8s-admission/`.

**Options:**

| Option | Trade-off |
|--------|-----------|
| **No separate category** | New shapes go into `k8s-admission/`. Conftest-style shapes are documented as a dual-mode variant. |
| **Separate `k8s-manifest/` category** | Clean separation by input shape. But most shapes would be duplicated. |
| **Dual-mode templates** | One template with an `InputMode` parameter (admission vs manifest). One category, no duplication. Requires `lib/kubernetes.rego` for input normalization. |

**Decision:** Not yet made. Current README lists shapes under `k8s-admission/` with
a note that `component-flag-check` and `pod-field-check` are planned.

---

## Cross-cutting

### OQ-7: `lib/` versioning and compatibility

**Context:** Now that `lib/resource_units.rego` exists and shapes depend on it, what
happens when a library is updated? Breaking changes to helper signatures would break
all shapes that depend on them.

**Proposal:** Libraries follow the same semver as shapes (per SPEC). Breaking changes
to exported rules = major bump. But the SPEC doesn't currently define how lib versions
are tracked or how shapes declare which lib version they need.

**Decision:** Not yet made. Low urgency — only one library exists today.

---

## How to resolve

1. Pick a question
2. Do a design exploration if needed (see design-explore skill)
3. Record the decision in this file (change "Not yet made" to the decision + date)
4. Update the relevant taxonomy doc and README
5. Proceed with implementation
