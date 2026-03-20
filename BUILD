load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

# Prefer generated BUILD files to be called BUILD over BUILD.bazel
# gazelle:build_file_name BUILD,BUILD.bazel
# gazelle:prefix github.com/arkeros/helm.bzl
# gazelle:exclude bazel-helm.bzl

exports_files([
    "BUILD",
    "LICENSE",
    "MODULE.bazel",
])

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "helm",
    srcs = ["helm.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//helm:defs",
        "//toolchain",
    ],
)
