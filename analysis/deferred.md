# Deferred Shapes

Shapes identified in the corpus analysis that cannot be cleanly expressed as
parameterized `text/template` files under the current shape contract. Each entry
documents why it was deferred and what approach would be needed.

---

## ~~container-resource-limit-check~~ (resolved)

**Status:** ✅ Shipped — resolved via `lib/resource_units.rego` (Option 2: repo-level
shared library). SPEC contract #4 amended to allow `data.lib.*` imports from
repo-provided libraries.

See `shapes/k8s-admission/container-resource-limit-check/` and `lib/resource_units.rego`.

Template partials (Option 3) remain tracked as an alternative approach in
[#1](https://github.com/sonupreetam/rego-shapes/issues/1).

---

## tf-cross-resource-check

**Corpus coverage:** ~10 policies (11% of aws-samples terraform corpus)

**Sample policies:** `ec2linux-r-1`, `opensearch-m-1`, `lambda-m-1`, `cloudwatch-m-1`

### Why it's deferred

These policies don't validate a single resource in isolation — they **correlate
across multiple resources** in `input.resource_changes` or **unmarshal embedded JSON
policies** (IAM, resource policies). Each policy has 3–8 complex helper rules with
unique correlation logic:

- `ec2linux-r-1` — cross-references security groups with EC2 instances
- `lambda-m-1` — unmarshals an embedded IAM policy JSON, inspects `Statement[_]`
  conditions
- `cloudwatch-m-1` — walks multiple resource types to verify alarm configurations
- `opensearch-m-1` — correlates domain config with VPC and encryption settings

### Why it can't be templated

Each cross-resource check has **unique correlation logic**. Unlike shapes 1–4 in the
terraform-plan taxonomy, there is no recurring structural pattern — the helpers,
iteration depth, and correlation keys are different for every policy.

A template would need to parameterize:
- Which resource types to correlate
- The join key between resources
- Whether to unmarshal embedded JSON
- The condition logic on the correlated result
- The `walk`/iteration pattern for nested structures

This is effectively parameterizing the entire policy, which defeats the purpose of
a shape.

### Recommendation

This is a **"long tail"** category — better suited for AI-with-guardrails or
hand-authoring. A shape could potentially be created for the `json.unmarshal` +
IAM policy inspection sub-pattern (covers ~4 policies), but the broader
cross-resource correlation is too varied.

---

## Deferred Categories

Categories or shape groups from the corpus analysis that are documented but not
yet approved for shape implementation.

### flat-config-deny (Conftest non-K8s configs)

**Corpus coverage:** 11 policies (Conftest examples)
**Source:** conftest/examples (INI, TOML, HOCON, .env, Compose, Nginx, VCL, etc.)

**Why deferred:** Input shapes are too varied — each config format has different
structure. There is no recurring structural pattern across formats. Individual
templates per config format would be needed, but no single format has ≥3 shapes
covering ≥10 policies.

### rbac-rule-check (K8s RBAC)

**Corpus coverage:** 3 policies (raspbernetes CIS.5.1.x)

**Why deferred:** Only 3 policies, each with structurally unique set-intersection
logic. Does not meet the ≥2 policy threshold for a shape. Could revisit if more
RBAC policy sources are analyzed.

### resource-multi-field-check (multi-resource correlation)

**Corpus coverage:** 2 policies (raspbernetes CIS.5.1.5, CIS.5.1.6)

**Why deferred:** Multi-resource iteration (pods + serviceaccounts) with cross-resource
field matching. Too few policies and too varied to template.

---

## Design Decisions Made

### Option 2 (repo-level `lib/`) chosen over Option 3 (template partials)

**Date:** 2026-07-23
**Context:** Shapes needing shared helpers (resource units, flag parsing, TF utils)

**Decision:** Ship shared Rego libraries in `lib/` that generated policies import
at runtime via `data.lib.*`. SPEC contract #4 amended accordingly.

**Rationale:** Clean separation, single source of truth for bug fixes, matches how
OPA bundles already work. Trade-off: consumers must deploy `lib/` alongside policies.

**Alternative tracked:** Template partials (Option 3) filed as
[#1](https://github.com/sonupreetam/rego-shapes/issues/1) for future consideration.
Offers self-contained output but breaks cross-engine portability.

---

## How to add entries to this file

When a corpus policy cluster can't be expressed as a clean shape, document:

1. **Corpus coverage** — how many policies it would cover
2. **Why it's deferred** — what specifically violates the shape contract
3. **What it needs instead** — the alternative approach
4. **Blockers** — what SPEC or infrastructure changes are prerequisites
5. **Recommendation** — the proposed path forward
