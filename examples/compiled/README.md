# Compiled Example

Compiles helm from Go source using `rules_go` and registers it as a custom toolchain.
This provides fully hermetic builds — no pre-built binary download needed.

## Setup

Generate Go dependencies:

```bash
go mod tidy
```

## Usage

```bash
bazel build :otel_collector
cat bazel-bin/otel_collector.yaml
```

## How It Works

1. `go.mod` declares `helm.sh/helm/v3` as a dependency
2. `gazelle` resolves Go deps into Bazel targets via `go_deps`
3. `helm_toolchain` wraps the compiled `@sh_helm_helm_v3//cmd/helm` binary
4. `register_toolchains("//:helm_toolchain")` in MODULE.bazel makes it the default
5. `helm_template` uses the compiled binary via the toolchain
