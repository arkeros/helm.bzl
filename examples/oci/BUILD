load("@helm.bzl", "helm_template")

# Render an OCI-hosted Helm chart
helm_template(
    name = "atlas_operator",
    chart = "@atlas_operator",
    create_namespace = True,
    include_crds = True,
    namespace = "atlas-operator",
    release_name = "atlas-operator",
    values = "values.yaml",
)
