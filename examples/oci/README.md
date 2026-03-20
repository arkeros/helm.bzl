# OCI Example

Downloads and renders a Helm chart from an OCI registry (GitHub Container Registry).

Demonstrates:

- `helm.oci_chart()` for OCI-hosted charts
- `include_crds` and `create_namespace` options

## Usage

```bash
bazel build :atlas_operator
cat bazel-bin/atlas_operator.yaml
```
