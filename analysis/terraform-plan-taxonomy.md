# Terraform Plan — Shape Taxonomy

**Source:** [aws-samples/aws-infra-policy-as-code-with-terraform](https://github.com/aws-samples/aws-infra-policy-as-code-with-terraform)
**Policies analyzed:** 90 (across 28 AWS services)
**Sample depth:** 21 policies read in full, remainder classified by structure scan

## Input Shape

All policies operate on the **Terraform plan JSON** (`terraform show -json`).

Universal input paths:

| Path | Purpose |
|------|---------|
| `input.resource_changes[_].mode` | `"managed"` filter |
| `input.resource_changes[_].type` | Resource type filter (`aws_lb`, `aws_eks_cluster`, …) |
| `input.resource_changes[_].change.actions` | Create/update/delete action filter |
| `input.resource_changes[_].change.after.*` | Post-apply resource attributes |
| `input.resource_changes[_].change.after_unknown.*` | Computed values (unknown at plan time) |
| `input.resource_changes[_].address` | Resource address for error messages |
| `input.configuration.root_module.*` | Terraform config (expressions, references) |

## Universal Rule Structure

Every policy in this corpus shares:

- **Rule head:** `deny[reason]` — partial string set via `sprintf`
- **Iteration:** `resource := input.resource_changes[_]`
- **Scoping:** Type + action filter (inline or via `is_in_scope` helper)
- **Utils:** 86% import `data.utils` for `is_create_or_update`, `find_configuration_resource`

## Shape Taxonomy

| # | Shape | Policies | Coverage | Templateable |
|---|-------|----------|----------|:------------:|
| 1 | [tf-resource-field-check](#1-tf-resource-field-check) | ~45 | 50% | ✅ |
| 2 | [tf-config-reference-check](#2-tf-config-reference-check) | ~18 | 20% | ⚠️ |
| 3 | [tf-field-in-set](#3-tf-field-in-set) | ~12 | 13% | ✅ |
| 4 | [tf-inline-flat-deny](#4-tf-inline-flat-deny) | ~10 | 11% | ✅ |
| 5 | [tf-cross-resource-check](#5-tf-cross-resource-check) | ~10 | 11% | ❌ |

> Some policies contain multiple `deny[reason]` rules mapping to different shapes.
> Percentages sum to >100% due to multi-deny files.

---

### 1. tf-resource-field-check

**Coverage:** ~45 policies (50%)

Iterate `resource_changes`, scope by type+action, define an `is_in_scope` helper
and a single predicate helper that checks a field in `change.after.*`. The
`deny[reason]` body negates the predicate.

**Canonical structure:**

```rego
is_in_scope(resource) {
    resource.mode == "managed"
    data.utils.is_create_or_update(resource.change.actions)
    resource.type == "<aws_resource_type>"
}

is_<condition>(resource) {
    resource.change.after.<field_path> == <expected_value>
}

deny[reason] {
    resource := input.resource_changes[_]
    is_in_scope(resource)
    not is_<condition>(resource)
    reason := sprintf("<message> '%s'", [resource.address])
}
```

**Condition variants:** boolean truthiness, equality, `count > 0`, `not is_null`,
`startswith`.

**Sample policies:** `acm-m-1`, `redshift-m-1`, `eks-r-1`, `eks-r-2`, `elb-m-1`,
`mwaa-m-1`, `opensearch-r-1`, `msk-m-1`

**Templateable:** ✅ — Parameters: resource type, field path, expected value,
condition operator, message template.

---

### 2. tf-config-reference-check

**Coverage:** ~18 policies (20%)

Same iteration/scoping, but the predicate needs data from
`input.configuration.root_module` (Terraform expressions/references). Uses
`data.utils.find_configuration_resource(input, resource)` to resolve references.
Often has multi-branch `else` chains to handle both `constant_value` and
`references` cases.

**Canonical structure:**

```rego
is_<condition>(resource) {
    not is_null(resource.change.after.<field>)
    startswith(resource.change.after.<field>, "arn:aws:kms:")
} else {
    config_resource := data.utils.find_configuration_resource(input, resource)
    references := config_resource.expressions.<field>.references[_]
    contains(references, "aws_kms_key.")
}
```

**Sample policies:** `efs-m-1`, `systemsmanager-m-1`, `route53-r-1`, `lambda-r-1`

**Templateable:** ⚠️ — The `else` branching and `find_configuration_resource`
dependency make this harder to template. The config-resolution logic is
effectively a library concern.

---

### 3. tf-field-in-set

**Coverage:** ~12 policies (13%)

The predicate compares a resource field against a **pre-defined constant set** or
array. Uses set difference (`valid - actual`), array membership, or
`contains_element`.

**Canonical structure:**

```rego
valid_values := {"value_a", "value_b", "value_c"}

is_<condition>(resource) {
    actual := {v | v := resource.change.after.<field>[_]}
    missing := valid_values - actual
    count(missing) == 0
}
```

**Sample policies:** `apigateway-m-1`, `apigateway-r-1`, `eks-m-1`

**Templateable:** ✅ — Parameters: resource type, field path, valid set, check
mode (all-required vs any-allowed).

---

### 4. tf-inline-flat-deny

**Coverage:** ~10 policies (11%)

No helper rules at all — scope checks and condition are inlined directly in the
`deny[reason]` body. Typically < 15 lines of policy logic.

**Canonical structure:**

```rego
deny[reason] {
    resource := input.resource_changes[_]
    resource.mode == "managed"
    resource.type == "<type>"
    data.utils.is_create_or_update(resource.change.actions)
    not resource.change.after.<field> == <value>
    reason := sprintf("<message>", [resource.type])
}
```

**Sample policies:** `ec2linux-m-1`, `pl-m-1`

**Templateable:** ✅ — This is a simplified variant of `tf-resource-field-check`.
Could be generated from the same template with a "compact" option, or kept
separate for clarity.

---

### 5. tf-cross-resource-check

**Coverage:** ~10 policies (11%)

The deny rule correlates **across multiple resources** in `resource_changes` or
**unmarshals embedded JSON** (IAM policies, resource policies). Has 3–8 complex
helper rules with inner iterations, `walk`, `json.unmarshal`, or string splitting.

**Canonical structure:**

```rego
deny[reason] {
    resource := input.resource_changes[_]
    is_in_scope(resource)
    policyString := resource.change.after.policy
    policy := json.unmarshal(policyString)
    statement := policy.Statement[_]
    not has_required_condition(statement)
    reason := sprintf(...)
}
```

**Sample policies:** `ec2linux-r-1`, `opensearch-m-1`, `lambda-m-1`, `cloudwatch-m-1`

**Templateable:** ❌ — Too structurally varied. Each cross-resource check has
unique correlation logic. Better suited for AI-with-guardrails or hand-authoring.

---

## Structural Notes

1. **`else = false { true }` idiom** — Widely used as a "default false" branch for
   helper predicates (ensures `false` return instead of `undefined`).

2. **Multi-deny files** — ~20 policies contain 2+ `deny[reason]` rules checking
   different aspects of the same resource.

3. **Utils dependency** — The `common.utils` package provides `is_create_or_update`,
   `find_configuration_resource`, `contains_element`, and object-path helpers. Shapes
   1–4 would benefit from a similar shared library in rego-shapes.

## Gate Assessment

| Criterion | Result |
|-----------|--------|
| ≥3 distinct shapes | ✅ 5 shapes |
| Each covering ≥10 policies | ✅ All 5 meet threshold |
| From public sources | ✅ aws-samples (Apache 2.0) |

**Category `terraform-plan` is approved for shape development.**

## Priority Shapes for Implementation

1. **`tf-resource-field-check`** — 45 policies, clean template surface
2. **`tf-field-in-set`** — 12 policies, straightforward parameterization
3. **`tf-inline-flat-deny`** — 10 policies (or merge with #1 as compact variant)
