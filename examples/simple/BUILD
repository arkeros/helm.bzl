load("@helm.bzl", "helm_template")

# Basic chart rendering with set overrides
helm_template(
    name = "otel_collector",
    chart = "@opentelemetry_collector",
    namespace = "observability",
    release_name = "otel-collector",
    set = {
        "image.repository": "otel/opentelemetry-collector-contrib",
        "mode": "daemonset",
    },
)

# Chart rendering with a values file
helm_template(
    name = "otel_collector_custom",
    chart = "@opentelemetry_collector",
    namespace = "observability",
    release_name = "otel-collector",
    values = "values.yaml",
)

# Chart rendering with Starlark dict values (recommended for complex configs)
helm_template(
    name = "otel_collector_starlark",
    chart = "@opentelemetry_collector",
    namespace = "observability",
    release_name = "otel-collector",
    values_starlark = {
        "image": {
            "repository": "otel/opentelemetry-collector-contrib",
        },
        "mode": "daemonset",
        "resources": {
            "limits": {
                "cpu": "500m",
                "memory": "512Mi",
            },
        },
    },
)

# Chart rendering with dot-notation overrides
helm_template(
    name = "otel_collector_set",
    chart = "@opentelemetry_collector",
    namespace = "observability",
    release_name = "otel-collector",
    set = {
        "image.repository": "otel/opentelemetry-collector-contrib",
        "mode": "daemonset",
        "resources.limits.cpu": "500m",
        "resources.limits.memory": "512Mi",
    },
)
