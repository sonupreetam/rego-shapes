# Corpus Analysis

Methodology for deriving Rego shapes from existing policy libraries.

## Documents

| File | Content |
|------|---------|
| [taxonomy.md](taxonomy.md) | K8s admission shapes from gatekeeper-library (49 policies, 20 shapes) |
| [terraform-plan-taxonomy.md](terraform-plan-taxonomy.md) | Terraform plan shapes from aws-samples (90 policies, 5 shapes) |
| [k8s-manifest-taxonomy.md](k8s-manifest-taxonomy.md) | K8s manifest shapes from raspbernetes + conftest + instrumenta + redhat-cop (134 policies, 8 shapes) |
| [deferred.md](deferred.md) | Shapes and categories that can't be cleanly templated, plus design decisions made |
| [open-questions.md](open-questions.md) | Unresolved design questions that need decisions before implementation |

## Analyzed Sources

| Source | Policies | Category |
|--------|:--------:|----------|
| [gatekeeper-library](https://github.com/open-policy-agent/gatekeeper-library) | 49 | k8s-admission |
| [aws-samples/aws-infra-policy-as-code-with-terraform](https://github.com/aws-samples/aws-infra-policy-as-code-with-terraform) | 90 | terraform-plan |
| [raspbernetes/k8s-security-policies](https://github.com/raspbernetes/k8s-security-policies) | 62 | k8s-manifest |
| [conftest examples](https://github.com/open-policy-agent/conftest/tree/master/examples) | 12 | k8s-manifest |
| [instrumenta/policies](https://github.com/instrumenta/policies) | ~30 | k8s-manifest |
| [redhat-cop/rego-policies](https://github.com/redhat-cop/rego-policies) | ~30 | k8s-manifest |

## Methodology

For each policy in the corpus, answer five structural questions:

1. **How many `input.*` paths are accessed?** (single-path vs multi-path)
2. **Is there iteration?** (`some`, comprehensions, `containers[_]`)
3. **What's the rule head shape?** (`deny`, `violation`, `warn`, `deny contains msg if`)
4. **How is the violation condition expressed?** (equality, inequality, negation, set membership, regex)
5. **Are there helper rules or data references?** (`data.inventory`, helper functions)

## Classification

Policies are classified by **structural shape**, not by what they check or which
compliance framework they belong to. Two policies that check different things but have
the same Rego structure belong to the same shape.

## Validation

After defining shapes, hold out 10 random unclassified policies and attempt to fit each
into the taxonomy. Target: 80%+ coverage. Below 70% means a shape is missing. Above 90%
means shapes can likely be merged.
