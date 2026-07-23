# rego-shapes

Parameterized Rego policy shapes for deterministic generation from structured input.

## The Problem

Plenty of Rego policy *libraries* exist — collections of fixed, hand-written policies you
copy and adapt. And plenty of AI tools can *generate* Rego from natural language, with
varying degrees of correctness.

What's missing is the middle ground: a library of **parameterized policy shapes** with
schemas, so a tool can call `f(shape, params) → valid Rego` and get a correct,
deterministic result every time — no LLM, no copy-paste.

## What's a Shape?

A shape is a structural pattern that recurs across Rego policies, independent of what's
being checked. For example, "iterate over all containers in a pod spec and check a field
on each one" is a shape. Whether you're checking `runAsNonRoot`, `resource.limits`, or
`imagePullPolicy` — the Rego structure is the same, only the parameters change.

Each shape in this repo includes:

```
shapes/<shape-name>/
├── template.rego.tmpl   # Go text/template — the parameterized Rego
├── params.json          # JSON Schema for the template parameters
├── examples/            # Concrete policies generated from this shape
│   ├── <example>.rego
│   └── <example>_test.rego
└── README.md            # When to use, pitfalls, related shapes
```

## Shape Catalog

Shapes are derived from structural analysis of public policy corpora — not invented
speculatively. See [analysis/taxonomy.md](analysis/taxonomy.md) for the full
classification and methodology.

### Kubernetes Admission (`shapes/k8s-admission/`)

Derived from 49 policies in [gatekeeper-library](https://github.com/open-policy-agent/gatekeeper-library)
plus 134 policies from [raspbernetes](https://github.com/raspbernetes/k8s-security-policies),
[instrumenta](https://github.com/instrumenta/policies), and
[redhat-cop](https://github.com/redhat-cop/rego-policies).

| Shape | Corpus Coverage | Status |
|-------|:-:|:-:|
| `container-field-check` | 15 policies | ✅ shipped |
| `container-field-in-allowlist` | 7 policies | ✅ shipped |
| `container-resource-limit-check` | 5 policies | ✅ shipped |
| `container-image-allowlist` | 2 policies | ✅ shipped |
| `container-image-denylist` | 2 policies | ✅ shipped |
| `metadata-must-have` | 2 policies | ✅ shipped |
| `resource-field-equality-block` | 2 policies | ✅ shipped |
| `resource-numeric-range-check` | 2 policies | ✅ shipped |
| `component-flag-check` | 36 policies | planned |
| `pod-field-check` | 7 policies | planned |

### Terraform Plan (`shapes/terraform-plan/`)

Derived from 90 policies in [aws-samples/aws-infra-policy-as-code-with-terraform](https://github.com/aws-samples/aws-infra-policy-as-code-with-terraform).
5 structural shapes identified; all 5 cover ≥10 policies each.
See [analysis/terraform-plan-taxonomy.md](analysis/terraform-plan-taxonomy.md).

| Shape | Corpus Coverage | Status |
|-------|:-:|:-:|
| `tf-resource-field-check` | ~45 policies | planned |
| `tf-config-reference-check` | ~18 policies | planned |
| `tf-field-in-set` | ~12 policies | planned |
| `tf-inline-flat-deny` | ~10 policies | planned |
| `tf-cross-resource-check` | ~10 policies | [deferred](analysis/deferred.md) |

Future categories (RBAC, API authz, CI/CD) require their own corpus analysis
before shapes can be added. See [SPEC.md](SPEC.md) for scope boundaries.

## Usage

### With Go `text/template`

```go
tmpl, _ := template.ParseFiles("shapes/k8s-admission/container-field-check/template.rego.tmpl")
tmpl.Execute(os.Stdout, map[string]any{
    "Package":          "k8s.container_root",
    "FieldPath":        "securityContext.runAsNonRoot",
    "Operator":         "!=",
    "ExpectedValue":    "true",
    "ViolationMessage": "containers must not run as root",
})
```

### With any template engine

The `.rego.tmpl` files use Go `text/template` syntax (`{{.Param}}`), but the pattern
is simple enough to port to Jinja2, Gomplate, Jsonnet, or any other templating tool.

### With AI (as guardrails)

Use shapes as the *primary* generation path for known patterns. Fall back to AI for
requirements that don't fit a shape, and validate AI output with OPA's toolchain
(`opa check`, `opa test`, Regal lint).

## Corpus Analysis

The `analysis/` directory contains the structural analysis that informed the shape
taxonomy:

- [analysis/taxonomy.md](analysis/taxonomy.md) — **49 policies** from gatekeeper-library,
  20 shapes identified (k8s-admission)
- [analysis/terraform-plan-taxonomy.md](analysis/terraform-plan-taxonomy.md) — **90 policies**
  from aws-samples, 5 shapes identified (terraform-plan)
- [analysis/k8s-manifest-taxonomy.md](analysis/k8s-manifest-taxonomy.md) — **134 policies**
  from raspbernetes, conftest, instrumenta, redhat-cop (k8s-manifest/conftest)
- [analysis/deferred.md](analysis/deferred.md) — shapes that can't be cleanly
  templated under the current contract

See [analysis/README.md](analysis/README.md) for methodology.

## Shared Libraries (`lib/`)

Some shapes require substantial helper logic (unit conversion, input normalization) that
would be wasteful to duplicate in every generated policy. These are provided as shared
Rego libraries in `lib/`:

| Library | Purpose | Used by |
|---------|---------|---------|
| `lib/resource_units.rego` | CPU/memory/storage quantity canonicalization | `container-resource-limit-check` |

Consumers that use shapes with library dependencies must deploy `lib/` alongside their
generated policies. See [SPEC.md](SPEC.md#shared-libraries-lib) for the library contract.

## Corpus Sources

The `corpus/` directory tracks the public policy collections analyzed to derive the shapes.
No policies are vendored — only references and classification notes.

## Design Principles

1. **Shapes, not policies.** A shape is a Rego structural pattern. A policy is an
   instantiation of a shape with specific parameters. This repo provides shapes.

2. **Deterministic.** Given the same shape and parameters, the output is identical.
   No AI, no randomness, no network calls.

3. **Testable.** Every shape includes example outputs with OPA test cases. Shapes are
   validated in CI by generating examples and running `opa test` on them.

4. **Composable.** Complex policies can be assembled from multiple shapes. A
   "hardened pod" policy might compose `container-field-check` (runAsNonRoot) +
   `container-field-check` (resource limits) + `required-labels`.

5. **Language-neutral parameters.** Parameter schemas are JSON Schema. Any tool
   that can produce a JSON object matching the schema can use the shapes.

## Contributing

1. Identify a recurring Rego pattern in the wild
2. Extract the structural shape (what varies, what stays fixed)
3. Write the `.rego.tmpl` with parameter placeholders
4. Add at least two examples with tests
5. Document when to use the shape and common pitfalls

## License

[Apache-2.0](LICENSE)
