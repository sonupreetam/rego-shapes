# Corpus Sources

References to public Rego policy collections used to derive the shape taxonomy.
No policies are vendored — this directory tracks what was analyzed and how it was classified.

New shape categories require corpus analysis before any shapes can be added.
See [SPEC.md](../SPEC.md) for the gate: ≥3 distinct shapes covering ≥10 policies.

## Analyzed Sources

| Source | Category | Policies Analyzed | Shapes Found | Status |
|--------|----------|:-:|:-:|:---:|
| [open-policy-agent/gatekeeper-library](https://github.com/open-policy-agent/gatekeeper-library) | k8s-admission | 49 | 20 | ✅ complete |

## Candidate Sources for Future Analysis

Sources identified as having real, public Rego policies suitable for structural analysis.
Not yet analyzed — listed here so contributors know where to look.

### IaC Gates (Terraform / CloudFormation)

| Source | Est. Policies | Notes |
|--------|:---:|-------|
| [open-policy-agent/conftest — examples](https://github.com/open-policy-agent/conftest/tree/master/examples) | ~20 | Terraform, Dockerfile, K8s YAML, multi-format |
| [fugue/regula](https://github.com/fugue/regula/tree/master/rego/rules) | ~40 | AWS/Azure/GCP rules for Terraform + CloudFormation |
| [spacelift-io/spacelift-policies-example-library](https://github.com/spacelift-io/spacelift-policies-example-library) | ~15 | Terraform plan/apply gates |
| [aws-samples/aws-infra-policy-as-code-with-terraform](https://github.com/aws-samples/aws-infra-policy-as-code-with-terraform) | ~30 | AWS-specific OPA rules for Terraform plans, per-service (S3, EFS, IAM, etc.) |
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

Distinct from k8s-admission: these policies validate static YAML manifests in CI,
not admission requests at the API server. Different `input` shape (raw manifest vs
admission review envelope).

| Source | Est. Policies | Notes |
|--------|:---:|-------|
| [instrumenta/policies](https://github.com/instrumenta/policies) | ~15 | Shared Conftest policies for K8s deployments (limits, capabilities, read-only fs) |
| [redhat-cop/rego-policies](https://github.com/redhat-cop/rego-policies) | ~30 | Red Hat CoP policies for Conftest + Gatekeeper dual-use |
| [raspbernetes/k8s-security-policies](https://github.com/raspbernetes/k8s-security-policies) | ~20 | CIS Kubernetes Benchmark mapped to Rego; Conftest + Gatekeeper compatible |
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

## How to Analyze a New Source

1. Clone the repo, find all `.rego` files (exclude tests)
2. For each policy, answer the 5 structural questions from [analysis/README.md](../analysis/README.md)
3. Cluster by structure, not by domain
4. If ≥3 shapes covering ≥10 policies → add the category
5. Document results in `analysis/taxonomy.md` and update this file
