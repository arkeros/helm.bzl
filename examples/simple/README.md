# Simple Example

Renders Helm charts using a pre-built helm binary downloaded via the toolchain extension.

Demonstrates four ways to pass values:

- Default values only
- Values file (`values.yaml`)
- Starlark dict (`values_starlark`)
- Dot-notation overrides (`set`)

## Usage

```bash
# Render with default values
bazel build :otel_collector

# Render with values file
bazel build :otel_collector_custom

# Render with Starlark dict
bazel build :otel_collector_starlark

# Render with dot-notation overrides
bazel build :otel_collector_set
```

Inspect the output:

```bash
cat bazel-bin/otel_collector.yaml
```
