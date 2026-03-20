load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

bzl_library(
    name = "defs",
    srcs = ["defs.bzl"],
    deps = ["//toolchain"],
)

bzl_library(
    name = "extensions",
    srcs = ["extensions.bzl"],
    deps = [":versions"],
)

bzl_library(
    name = "versions",
    srcs = ["versions.bzl"],
)
