load("@helm.bzl", "helm_template", "helm_toolchain")

# Custom toolchain using helm compiled from Go source
helm_toolchain(
    name = "compiled_helm_toolchain",
    helm = "@sh_helm_helm_v3//cmd/helm",
    visibility = ["//visibility:public"],
)

toolchain(
    name = "helm_toolchain",
    toolchain = ":compiled_helm_toolchain",
    toolchain_type = "@helm.bzl//:toolchain_type",
)

# Use the compiled toolchain to render a chart
helm_template(
    name = "otel_collector",
    chart = "@opentelemetry_collector",
    namespace = "observability",
    release_name = "otel-collector",
)
