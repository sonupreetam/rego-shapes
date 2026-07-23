# Project Status

Last updated: 2026-07-23

## Shipped Shapes (8)

All shapes in `shapes/k8s-admission/` with passing OPA tests.

| Shape | Corpus Coverage | Lib Dependency | Tests |
|-------|:-:|:-:|:-:|
| `container-field-check` | 15 policies | — | ✅ |
| `container-field-in-allowlist` | 7 policies | — | ✅ |
| `container-resource-limit-check` | 5 policies | `lib/resource_units.rego` | ✅ |
| `container-image-allowlist` | 2 policies | — | ✅ |
| `container-image-denylist` | 2 policies | — | ✅ |
| `metadata-must-have` | 2 policies | — | ✅ |
| `resource-field-equality-block` | 2 policies | — | ✅ |
| `resource-numeric-range-check` | 2 policies | — | ✅ |

## Shared Libraries (1)

| Library | Purpose | Tests |
|---------|---------|:-:|
| `lib/resource_units.rego` | CPU/memory/storage quantity canonicalization | ✅ 20 tests |

## Corpus Analysis Complete (3 categories)

| Category | Source | Policies | Shapes Found | Taxonomy Doc |
|----------|--------|:--------:|:------------:|:------------:|
| k8s-admission | gatekeeper-library | 49 | 20 | [taxonomy.md](analysis/taxonomy.md) |
| terraform-plan | aws-samples | 90 | 5 | [terraform-plan-taxonomy.md](analysis/terraform-plan-taxonomy.md) |
| k8s-manifest | raspbernetes + conftest + instrumenta + redhat-cop | 134 | 8 | [k8s-manifest-taxonomy.md](analysis/k8s-manifest-taxonomy.md) |

## Planned Shapes (not yet implemented)

### Kubernetes Admission — new shapes from k8s-manifest analysis

| Shape | Corpus Coverage | Blocked On | Priority |
|-------|:-:|---|:-:|
| `component-flag-check` | 36 policies | [OQ-4](analysis/open-questions.md#oq-4-component-flag-check-needs-flag-parsing-helpers): needs flag-parsing lib | High |
| `pod-field-check` | 7 policies | [OQ-5](analysis/open-questions.md#oq-5-should-pod-field-check-be-a-specialization-of-resource-field-equality-block): new shape or extend existing? | Medium |

### Terraform Plan — new category

| Shape | Corpus Coverage | Blocked On | Priority |
|-------|:-:|---|:-:|
| `tf-resource-field-check` | ~45 policies | [OQ-3](analysis/open-questions.md#oq-3-datautilsdependency-in-terraform-templates): utils dependency | High |
| `tf-field-in-set` | ~12 policies | — | Medium |
| `tf-inline-flat-deny` | ~10 policies | [OQ-1](analysis/open-questions.md#oq-1-merge-tf-inline-flat-deny-into-tf-resource-field-check): merge with tf-resource-field-check? | Low |
| `tf-config-reference-check` | ~18 policies | [OQ-2](analysis/open-questions.md#oq-2-tf-config-reference-check-needs-a-shared-library): needs shared lib | Deferred |

## Deferred (cannot template cleanly)

| Shape/Category | Why | Tracked In |
|----------------|-----|:----------:|
| `tf-cross-resource-check` | Too structurally varied (~10 policies) | [deferred.md](analysis/deferred.md) |
| `flat-config-deny` | Input shapes too varied (11 policies) | [deferred.md](analysis/deferred.md) |
| `rbac-rule-check` | Only 3 policies, each unique | [deferred.md](analysis/deferred.md) |
| `resource-multi-field-check` | Only 2 policies, cross-resource | [deferred.md](analysis/deferred.md) |

## Open Questions (7)

Design decisions needed before implementing planned shapes.
See [analysis/open-questions.md](analysis/open-questions.md) for details.

| ID | Question | Blocks |
|----|----------|--------|
| OQ-1 | Merge tf-inline-flat-deny into tf-resource-field-check? | `tf-inline-flat-deny` |
| OQ-2 | tf-config-reference-check needs shared library | `tf-config-reference-check` |
| OQ-3 | data.utils dependency in Terraform templates | `tf-resource-field-check` |
| OQ-4 | component-flag-check needs flag-parsing helpers | `component-flag-check` |
| OQ-5 | pod-field-check vs resource-field-equality-block | `pod-field-check` |
| OQ-6 | Separate k8s-manifest category or fold into k8s-admission? | category structure |
| OQ-7 | lib/ versioning and compatibility | all lib-dependent shapes |

## Open Issues

| # | Title | Type |
|---|-------|------|
| [#1](https://github.com/sonupreetam/rego-shapes/issues/1) | Template partials for shared Rego helper logic | enhancement (future) |

## Candidate Corpus Sources (not yet analyzed)

See [corpus/README.md](corpus/README.md) for the full list of candidate sources
that need corpus analysis before new categories can be added (IaC gates, RBAC/ABAC,
API authz, CI/CD, data filtering).
