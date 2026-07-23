# Corpus Sources

References to public Rego policy collections used to derive the shape taxonomy.
No policies are vendored — this directory tracks what was analyzed and how it was classified.

New shape categories require corpus analysis before any shapes can be added.
See [SPEC.md](../SPEC.md) for the gate: ≥3 distinct shapes covering ≥10 policies.

## Analyzed Sources

| Source | Category | Policies Analyzed | Shapes Found | Status |
|--------|----------|:-:|:-:|:---:|
| [open-policy-agent/gatekeeper-library](https://github.com/open-policy-agent/gatekeeper-library) | k8s-admission | 49 | 20 | ✅ complete |
| [aws-samples/aws-infra-policy-as-code-with-terraform](https://github.com/aws-samples/aws-infra-policy-as-code-with-terraform) | terraform-plan | 90 | 5 | ✅ complete |
| [raspbernetes/k8s-security-policies](https://github.com/raspbernetes/k8s-security-policies) | k8s-manifest | 62 | 6 | ✅ complete |
| [open-policy-agent/conftest — kubernetes examples](https://github.com/open-policy-agent/conftest/tree/master/examples/kubernetes) | k8s-manifest | 12 | 2 | ✅ complete |
| [instrumenta/policies](https://github.com/instrumenta/policies) | k8s-manifest | 15 rules (2 files) | 1 | ✅ complete |
| [redhat-cop/rego-policies](https://github.com/redhat-cop/rego-policies) | k8s-manifest | ~30 rules (60 files) | 1 | ✅ complete |

## Candidate Sources for Future Analysis

Sources identified as having real, public Rego policies suitable for structural analysis.
Not yet analyzed — listed here so contributors know where to look.

**Archived or inactive repos are valid sources.** Structural patterns don't expire —
a policy's Rego structure is the same whether the repo was last updated in 2020 or
2025. What matters is the pattern, not the maintenance status.

### IaC Gates (Terraform / CloudFormation)

| Source | Est. Policies | Notes |
|--------|:---:|-------|
| [open-policy-agent/conftest — examples (non-K8s)](https://github.com/open-policy-agent/conftest/tree/master/examples) | ~15 | Terraform HCL, Dockerfile, serverless — non-K8s examples |
| [fugue/regula](https://github.com/fugue/regula/tree/master/rego/rules) | ~40 | AWS/Azure/GCP rules for Terraform + CloudFormation |
| [spacelift-io/spacelift-policies-example-library](https://github.com/spacelift-io/spacelift-policies-example-library) | ~15 | Terraform plan/apply gates |
| [cmcconnell1/policy-as-code](https://github.com/cmcconnell1/policy-as-code) | ~25 | Multi-cloud (AWS + Azure) security, tagging, cost governance framework |

### RBAC / ABAC (Authorization)

| Source | Est. Policies | Notes |
|--------|:---:|-------|
| [OPA documentation tutorials](https://www.openpolicyagent.org/docs/latest/) | ~10 | HTTP API authz, RBAC, ABAC canonical examples |
| [OPA Playground — access control examples](https://play.openpolicyagent.org/?example-group=access-control) | ~8 | Interactive RBAC/ABAC/PBAC examples with input fixtures |
| [permitio/opal-example-policy-repo](https://github.com/permitio/opal-example-policy-repo) | ~5 | RBAC/ABAC with OPAL data updates |
| [cerbos/cerbos — test policies](https://github.com/cerbos/cerbos/tree/main/internal/test/testdata) | ~15 | Not Rego but structurally comparable; use for pattern validation |

### API Authorization

| Source | Est. Policies | Notes |
|--------|:---:|-------|
| [open-policy-agent/opa-envoy-plugin — examples](https://github.com/open-policy-agent/opa-envoy-plugin/tree/main/examples) | ~10 | Envoy ext_authz, JWT validation, path-based routing |
| [OPA HTTP API authz tutorial](https://www.openpolicyagent.org/docs/latest/http-api-authorization/) | ~5 | Canonical API gateway patterns |

### Kubernetes Config (Conftest — pre-deploy YAML validation)

| Source | Est. Policies | Notes |
|--------|:---:|-------|
| [rallyhealth/conftest-policy-packs](https://github.com/rallyhealth/conftest-policy-packs) | ~20 | Enterprise Compliance-as-Code policies with markdown violation messages |

### CI/CD Pipeline

| Source | Est. Policies | Notes |
|--------|:---:|-------|
| [open-policy-agent/conftest — examples](https://github.com/open-policy-agent/conftest/tree/master/examples) | ~10 | Dockerfile, GitHub Actions, YAML validation |
| [ynotbhatc/rego_policy_libraries — enforcement/cicd](https://github.com/ynotbhatc/rego_policy_libraries) | ~15 | Pipeline security, action pinning, secret detection |

### Data Filtering

| Source | Est. Policies | Notes |
|--------|:---:|-------|
| [StyraInc/opa-kafka-plugin](https://github.com/StyraInc/opa-kafka-plugin) | ~5 | Kafka topic authz, message filtering |
| OPA partial evaluation docs | ~5 | Row-level filtering patterns |

## Corpus Refresh

**Counting methodology:** The "Policies Analyzed" column above counts *rules
classified* during structural analysis, not `.rego` files. Some repos pack many
rules into one file (instrumenta: 15 rules in 2 files). The refresh script below
counts *files* for change detection — a different metric, useful for spotting repo
activity but not directly comparable to taxonomy policy counts.

Run `scripts/corpus-refresh.sh` periodically to check if analyzed sources have
added new policies since our last analysis:

```bash
./scripts/corpus-refresh.sh          # check for changes
./scripts/corpus-refresh.sh --update  # update baseline after re-analysis
```

Baseline counts are stored in `corpus/counts.json`. When the script reports new
policies, re-analyze the changed source and update the relevant taxonomy doc.

## How to Analyze a New Source

1. Clone the repo, find all `.rego` files (exclude tests)
2. For each policy, answer the 5 structural questions from [analysis/README.md](../analysis/README.md)
3. Cluster by structure, not by domain
4. If ≥3 shapes covering ≥10 policies → add the category
5. Document results in `analysis/<category>-taxonomy.md` with per-policy appendix
6. Update this file (move source from "Candidate" to "Analyzed")
7. Update [STATUS.md](../STATUS.md) and [README.md](../README.md)
8. Run `./scripts/corpus-refresh.sh --update` to set the new baseline
