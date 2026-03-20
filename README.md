# helm.bzl

Bazel rules for rendering [Helm](https://helm.sh/) charts using `helm template`.

Download Helm charts from HTTP repositories or OCI registries and render them into Kubernetes manifests as part of your Bazel build.

## Features

- Download charts from HTTP repositories or OCI registries
- Render charts with `helm template` (values files, Starlark dicts, dot-notation overrides)
- Hermetic builds with pinned chart digests (SHA256)
- Optional namespace manifest prepending
- Cross-platform support (Linux, macOS, Windows)

## Setup

Add to your `MODULE.bazel`:

```starlark
bazel_dep(name = "helm.bzl", version = "0.0.0")
git_override(
    module_name = "helm.bzl",
    remote = "https://github.com/arkeros/helm.bzl.git",
    commit = "...",
)

helm = use_extension("@helm.bzl//helm:extensions.bzl", "helm")

# Pre-built helm binary (optional if using a compiled toolchain)
helm.toolchain(version = "3.17.0")
use_repo(helm, "helm_toolchains")
register_toolchains("@helm_toolchains//:all")

# Declare chart repositories
helm.repo(
    name = "bitnami",
    url = "https://charts.bitnami.com/bitnami",
)

# Declare charts to download
helm.chart(
    repo = "bitnami",
    chart = "redis",
    name = "redis",
    version = "20.6.2",
    digest = "sha256:abc123...",
)

use_repo(helm, "redis")
```

### OCI Charts

```starlark
helm.oci_chart(
    name = "istio_base",
    registry = "ghcr.io",
    repository = "istio-release/helm/base",
    chart = "base",
    version = "1.24.3",
    digest = "sha256:abc123...",
)

use_repo(helm, "istio_base")
```

## Usage

### Basic

```starlark
load("@helm.bzl", "helm_template")

helm_template(
    name = "redis_manifests",
    chart = "@redis",
    release_name = "redis",
    namespace = "cache",
)
```

### Values file

```starlark
helm_template(
    name = "redis_manifests",
    chart = "@redis",
    values = "values.yaml",
    release_name = "redis",
    namespace = "cache",
)
```

### Starlark dict (recommended for complex values)

```starlark
helm_template(
    name = "kratos_manifests",
    chart = "@kratos",
    values_starlark = {
        "kratos": {
            "secret": {"enabled": False},
            "config": {
                "dsn": "$(DSN)",
                "secrets": {
                    "default": ["$(SECRETS_DEFAULT)"],
                },
            },
        },
    },
    release_name = "kratos",
    namespace = "identity",
)
```

### Dot-notation overrides

```starlark
helm_template(
    name = "redis_manifests",
    chart = "@redis",
    values = "values.yaml",
    set = {
        "replicaCount": "3",
        "image.tag": "v7.4.0",
    },
    release_name = "redis",
    namespace = "cache",
)
```

Values are applied in this order (later overrides earlier):

1. Chart's default `values.yaml`
2. `values` file
3. `values_starlark` / `values_json`
4. `set` dict

### Additional options

| Attribute | Type | Description |
|-----------|------|-------------|
| `chart` | label | Helm chart (required) |
| `release_name` | string | Helm release name (required) |
| `namespace` | string | Kubernetes namespace |
| `values` | label | YAML values file |
| `values_starlark` | dict | Starlark dict of values |
| `set` | string_dict | Dot-notation overrides |
| `include_crds` | bool | Include CRDs in output |
| `skip_tests` | bool | Skip test manifests |
| `kube_version` | string | Kubernetes version for rendering |
| `create_namespace` | bool | Prepend a Namespace manifest |
| `helm` | label | Custom helm binary (overrides toolchain) |

### Custom toolchain

For hermetic builds, compile helm from Go source and register as a toolchain:

```starlark
# BUILD
load("@helm.bzl", "helm_toolchain")

helm_toolchain(
    name = "compiled_helm_toolchain",
    helm = "@sh_helm_helm_v3//cmd/helm:helm",
)

toolchain(
    name = "helm_toolchain",
    toolchain = ":compiled_helm_toolchain",
    toolchain_type = "@helm.bzl//:toolchain_type",
)
```

```starlark
# MODULE.bazel
register_toolchains("//path/to:helm_toolchain")
```

## Examples

See the [`examples/`](examples/) directory:

- [`examples/simple/`](examples/simple/) - Pre-built helm binary with HTTP chart (values file, Starlark dict, dot-notation)
- [`examples/oci/`](examples/oci/) - Download and render a chart from an OCI registry
- [`examples/compiled/`](examples/compiled/) - Compile helm from Go source for fully hermetic builds

## License

Apache License 2.0
