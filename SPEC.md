# rego-shapes specification

Version: 0.1.0

## Problem Statement

Writing Rego policies from scratch is a high barrier for teams adopting OPA. Existing
solutions are either:

- **Fixed policy libraries** — copy a complete policy and modify it by hand
- **AI generation** — non-deterministic, requires validation infrastructure to trust
- **Proprietary platforms** — closed-source, SaaS-dependent

There is no open-source library of **parameterized Rego patterns** that produces correct,
deterministic output from structured input.

## Project Goal

Provide a catalog of parameterized Rego policy shapes — structural templates with schemas
— that any tool can render into valid, tested Rego policies deterministically.

**One sentence:** `f(shape, params) → valid Rego` — no LLM, no copy-paste, no vendor lock-in.

## Scope

### In Scope

1. **Shape catalog** — parameterized `.rego.tmpl` files using Go `text/template` syntax
2. **Parameter schemas** — JSON Schema definitions for each shape's inputs
3. **Working examples** — concrete policies generated from each shape, with OPA test cases
4. **Corpus analysis** — structural classification of existing public Rego policy libraries
   to derive and validate shapes
5. **Documentation** — when to use each shape, pitfalls, and what it covers from the
   corpus

### Out of Scope

1. **Template engine implementation** — this repo provides the shapes; consumers bring
   their own template engine (Go `text/template`, Gomplate, Jinja2, etc.)
2. **CLI tool** — no binary, no Go module, no `go install`. Just files.
3. **Gatekeeper YAML generation** — shapes produce `.rego` files, not ConstraintTemplate
   or Constraint YAML. Use [Konstraint](https://github.com/plexsystems/konstraint) for that.
4. **AI integration** — no LLM code, no MCP tools, no prompt engineering. Consumers
   that want AI fallback build that themselves.
5. **Runtime policy evaluation** — shapes are for generation-time, not evaluation-time.
6. **Policy-as-a-service** — no API, no server, no deployment infrastructure.
7. **Unanalyzed domains** — RBAC, ABAC, API authz, CI/CD are future categories.
   Current focus is Kubernetes admission control and Terraform plan validation. New
   categories require corpus analysis first: ≥3 distinct shapes covering ≥10 policies
   from public sources. See [corpus/README.md](corpus/README.md) for candidate sources.
8. **Compliance framework mapping** — shapes are structural, not tied to CIS/NIST/SOC2.
   Compliance mapping is the consumer's responsibility.

## Shape Contract

Every shape MUST include:

| File | Required | Description |
|------|:--------:|-------------|
| `template.rego.tmpl` | ✅ | Go `text/template` producing valid Rego v1 |
| `params.json` | ✅ | JSON Schema (2020-12) defining all template parameters |
| `README.md` | ✅ | When to use, pitfalls, corpus coverage |
| `examples/<name>.rego` | ✅ (≥2) | At least 2 concrete policies generated from the shape |
| `examples/<name>_test.rego` | ✅ (per example) | OPA test cases for each example |

Every shape MUST satisfy:

1. **Deterministic** — same shape + same params = byte-identical output
2. **Valid Rego v1** — output passes `opa check` with `import rego.v1`
3. **Tested** — all example tests pass via `opa test`
4. **Self-contained or lib-dependent** — shapes either include all helpers in the
   template (self-contained) or import from the repo's `lib/` directory
   (`data.lib.*`). External dependencies outside this repo are not allowed.
   Shapes that use `lib/` must document the required library files in their README.
5. **Parameterized** — at least one parameter must vary between examples. A shape with
   zero parameters is a fixed policy, not a shape.

## Shape Taxonomy Rules

1. Shapes are classified by **structure**, not by domain or compliance framework
2. Two policies with the same Rego structure but different fields belong to the **same shape**
3. A shape should cover **≥2 real-world policies** from the corpus. Singletons are
   documented in the taxonomy but not promoted to shapes unless they demonstrate clear
   reuse potential.
4. Shape names use `kebab-case` and describe the structural pattern, not the use case
   (e.g., `container-field-check`, not `block-privileged-containers`)

## Template Syntax Rules

1. Use Go `text/template` syntax (`{{.Param}}`)
2. Template output MUST be valid Rego that passes `opa fmt` without changes
3. Package name is always a parameter (`{{.Package}}`)
4. Templates MUST NOT contain hardcoded resource kinds, field paths, or values that
   should be parameterized
5. Templates SHOULD use `violation contains {"msg": msg} if` (Rego v1 set rule syntax)
6. Templates MUST iterate over all three container lists where applicable (containers,
   initContainers, ephemeralContainers)

## Shared Libraries (`lib/`)

The `lib/` directory contains shared Rego libraries that shapes may import. Libraries
exist for helper logic that is:

1. **Substantial** — too large to inline in every template (30+ lines)
2. **Reused** — shared across ≥2 shapes or ≥3 corpus policies
3. **Stable** — logic that is well-understood and unlikely to change frequently

### Library Contract

Every library MUST:

| Requirement | Description |
|-------------|-------------|
| Package under `lib.*` | e.g., `package lib.resource_units` |
| Rego v1 syntax | `import rego.v1` |
| Own test file | `lib/<name>_test.rego` with ≥5 tests |
| No external imports | Libraries must not import from shapes or other `data.*` paths outside `lib/` |
| Documentation | Header comment explaining purpose and usage |

### Consumer Deployment

Consumers that use shapes with `lib/` dependencies must deploy the library files
alongside their generated policies. OPA resolves `data.lib.*` imports at evaluation
time — if the library is missing, rules evaluate to `undefined` (no error).

## Quality Gates

Before merging a new shape:

- [ ] `opa check` passes on all examples
- [ ] `opa test` passes on all example tests (≥2 examples, ≥2 tests each)
- [ ] `params.json` is valid JSON Schema
- [ ] Template produces each example when rendered with documented params
- [ ] Shape covers ≥2 policies from the corpus analysis
- [ ] README documents when to use, pitfalls, and corpus coverage

## Versioning

- Shape schemas follow semver: breaking param changes = major bump
- Adding optional params = minor bump
- Documentation/example changes = patch bump
- The repo itself is versioned via git tags

## Non-Goals (Explicitly)

- **This is not a framework.** There is no `rego-shapes generate` command. There is no
  runtime dependency. Shapes are files you read with whatever tool you have.
- **This is not a policy library.** The examples are illustrative, not exhaustive. Use
  [gatekeeper-library](https://github.com/open-policy-agent/gatekeeper-library) or
  [rego_policy_libraries](https://github.com/ynotbhatc/rego_policy_libraries) for
  ready-to-deploy policies.
- **This is not an AI replacement.** Shapes cover common patterns deterministically.
  Uncommon patterns still need human authorship or AI-with-guardrails.

## Success Criteria

| Metric | Target |
|--------|--------|
| Shapes shipped | ≥10 covering ≥30 corpus policies |
| Corpus coverage | Top 13 shapes cover ≥76% of gatekeeper-library |
| Test pass rate | 100% on all examples |
| External consumers | ≥1 tool uses shapes for generation |
