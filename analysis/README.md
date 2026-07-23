# Corpus Analysis

Methodology for deriving Rego shapes from existing policy libraries.

## Sources

| Source | Policies Analyzed | URL |
|--------|-------------------|-----|
| Gatekeeper Library | ~40+ | https://github.com/open-policy-agent/gatekeeper-library |
| OPA Contrib | varies | https://github.com/open-policy-agent/contrib |

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
