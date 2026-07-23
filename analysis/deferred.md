# Deferred Shapes

Shapes identified in the corpus analysis that cannot be cleanly expressed as
parameterized `text/template` files under the current shape contract. Each entry
documents why it was deferred and what approach would be needed.

---

## container-resource-limit-check

**Corpus coverage:** 5 policies (10% of gatekeeper-library)

**Policies:** `containerlimits`, `containerrequests`, `containerresourceratios`,
`containerresources`, `ephemeralstoragelimit`

### Why it's deferred

These 5 policies share nearly identical boilerplate for CPU/memory/storage unit
canonicalization:

- `canonify_cpu/1` — converts CPU strings (`"100m"`, `"0.5"`, `"2"`) to millicores
- `canonify_mem/1` — converts memory strings (`"128Mi"`, `"1Gi"`, `"512000"`) to bytes
- `mem_multiple/1` — maps suffixes (`Ki`, `Mi`, `Gi`, `Ti`) to numeric multipliers
- `get_suffix/1` — extracts the unit suffix from a resource string
- `missing/2` — checks if a resource field is absent
- `general_violation` — intermediate rule that delegates to the main `violation` rule

A template for this shape would be **80+ lines of unit-conversion helpers** with a
~10-line policy at the top. This violates the shape contract in two ways:

1. **Self-contained becomes wasteful.** Every policy generated from this shape would
   duplicate the same 70 lines of conversion logic. If a bug is found in
   `canonify_mem`, every generated policy needs regeneration.

2. **The template is mostly library, not shape.** The parameterizable surface is small
   (which resource type, which field, what threshold), but the fixed boilerplate
   dominates the output.

### What it needs instead

**Library extraction.** The unit-conversion helpers should be a shared Rego library
(`lib/resource_units.rego`) that policies import:

```rego
import data.lib.resource_units.canonify_cpu
import data.lib.resource_units.canonify_mem
```

With the library extracted, the remaining shape would be simple and templateable:

```rego
package {{.Package}}

import rego.v1
import data.lib.resource_units

violation contains {"msg": msg} if {
    some container in input.review.object.spec.containers
    value := container.resources.{{.Field}}.{{.ResourceType}}
    limit := resource_units.canonify_{{.CanonifyFn}}(value)
    max := resource_units.canonify_{{.CanonifyFn}}(input.parameters.{{.ResourceType}})
    limit > max
    msg := sprintf(
        "Container '%s': %s %s exceeds maximum %s",
        [container.name, "{{.Field}}", "{{.ResourceType}}", input.parameters.{{.ResourceType}}],
    )
}
```

### Blockers

1. The shape contract says shapes must be **self-contained** — no `data.lib.*` imports.
   This would require either:
   - Relaxing the contract to allow a `lib/` directory in the repo
   - Inlining the library in the template (back to the 80-line problem)

2. The gatekeeper-library versions of these policies also reference
   `data.lib.exempt_container.is_exempt` and `data.lib.exclude_update.is_update`,
   which are Gatekeeper-specific library features. A pure shape can't replicate this
   without introducing a Gatekeeper dependency.

### Recommendation

Use template partials (`_helpers/resource_units.tmpl`) to share the helper logic at
generation time while keeping generated output self-contained. Tracked in
[#1](https://github.com/sonupreetam/rego-shapes/issues/1).

This shape is blocked on that proposal — once `_helpers/` is accepted, the thin
policy template on top is straightforward to implement.

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
