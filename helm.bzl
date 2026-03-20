"""Public API for helm.bzl module.

Usage in MODULE.bazel:
    helm = use_extension("@helm.bzl//helm:extensions.bzl", "helm")

    helm.repo(
        name = "ory",
        url = "https://k8s.ory.sh/helm/charts",
    )

    helm.chart(
        repo = "ory",
        chart = "kratos",
        name = "kratos",
        version = "0.47.0",
        digest = "sha256:abc123...",
    )

    use_repo(helm, "kratos")

Usage in BUILD files:
    load("@helm.bzl", "helm_template")

    helm_template(
        name = "kratos_manifests",
        chart = "@kratos",
        values = "values.yaml",
        set = {
            "replicaCount": "3",
            "image.tag": "v1.0.0",
        },
        release_name = "kratos",
        namespace = "identity",
    )

Custom toolchain (to use Go-built binary instead of pre-built):
    load("@helm.bzl", "helm_toolchain")

    helm_toolchain(
        name = "compiled_helm_toolchain",
        helm = "@sh_helm_helm_v3//cmd/helm:helm",
        visibility = ["//visibility:public"],
    )

    toolchain(
        name = "helm_toolchain",
        toolchain = ":compiled_helm_toolchain",
        toolchain_type = "@helm.bzl//:toolchain_type",
    )
"""

load("//helm:defs.bzl", _helm_template = "helm_template")
load("//toolchain:toolchain.bzl", _HelmInfo = "HelmInfo", _helm_toolchain = "helm_toolchain")

HelmInfo = _HelmInfo
helm_toolchain = _helm_toolchain
helm_template = _helm_template
