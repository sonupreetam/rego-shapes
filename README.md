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

## Shape Categories

| Category | Description | Examples |
|----------|-------------|----------|
| **k8s-admission** | Kubernetes admission control (Gatekeeper/OPA webhook) | container-field-check, required-labels, image-allowlist |
| **rbac** | Role-based access control | role-permission-map, hierarchical-roles |
| **abac** | Attribute-based access control | owner-access, org-scoped, classification-gate |
| **iac-gate** | Infrastructure-as-Code validation (Terraform, CloudFormation) | resource-field-check, iam-wildcard-deny |
| **api-authz** | HTTP/API request authorization | endpoint-allowlist, scope-check |
| **data-filter** | Data-level filtering and masking | field-redaction, row-filter |

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

The `analysis/` directory contains the structural analysis of existing Rego policy
libraries that informed the shape taxonomy:

- Source policies from [gatekeeper-library](https://github.com/open-policy-agent/gatekeeper-library), [OPA contrib](https://github.com/open-policy-agent/contrib), and other public collections
- Structural classification by Rego shape (not by domain or compliance framework)
- Coverage metrics: what percentage of real-world policies each shape covers

See [analysis/README.md](analysis/README.md) for methodology.

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
