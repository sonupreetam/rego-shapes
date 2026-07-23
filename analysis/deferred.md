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

## How to add entries to this file

When a corpus policy cluster can't be expressed as a clean shape, document:

1. **Corpus coverage** — how many policies it would cover
2. **Why it's deferred** — what specifically violates the shape contract
3. **What it needs instead** — the alternative approach
4. **Blockers** — what SPEC or infrastructure changes are prerequisites
5. **Recommendation** — the proposed path forward
