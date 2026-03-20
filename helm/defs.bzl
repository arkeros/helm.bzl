"""Helm template rule for rendering Helm charts."""

load("//toolchain:toolchain.bzl", "HelmInfo")

def _get_helm_binary(ctx):
    """Get the helm binary from custom attr or toolchain."""
    if ctx.attr.helm:
        return ctx.executable.helm
    toolchain = ctx.toolchains["@helm.bzl//:toolchain_type"]
    if not toolchain:
        fail("No helm toolchain found. Did you forget to call helm.toolchain() in MODULE.bazel?")
    return toolchain.helm_info.helm_binary

def _expand_dot_notation(flat_dict):
    """Expand a flat dict with dot-notation keys into a nested dict.

    Converts {"image.tag": "v1", "image.repo": "myrepo", "count": "3"}
    into {"image": {"tag": "v1", "repo": "myrepo"}, "count": "3"}

    Args:
        flat_dict: A flat dictionary with potentially dot-notation keys.

    Returns:
        A nested dictionary.
    """
    result = {}
    for key, value in flat_dict.items():
        parts = key.split(".")
        current = result
        for i, part in enumerate(parts[:-1]):
            if part not in current:
                current[part] = {}
            elif type(current[part]) != "dict":
                # Key collision: e.g., "a" and "a.b" both specified
                fail("Key collision: '{}' conflicts with a parent key".format(key))
            current = current[part]
        final_key = parts[-1]
        if final_key in current and type(current[final_key]) == "dict":
            fail("Key collision: '{}' conflicts with a nested key".format(key))
        current[final_key] = value
    return result

def _nested_dict_to_yaml(d, base_indent = 0):
    """Convert a nested dictionary to YAML format without recursion.

    Uses a stack-based DFS with bounded iterations to avoid Starlark's
    recursion and while-loop limitations.

    Args:
        d: The dictionary to convert.
        base_indent: Base indentation level.

    Returns:
        A YAML string representation of the dictionary.
    """
    lines = []

    # Stack for DFS: each entry is (type, data, indent)
    # type is "dict_start", "dict_item", "list_start", "list_item"
    # We process items from the end of the stack (LIFO)
    # Items are added in reverse order so they're processed in forward order
    stack = [("dict_start", d, base_indent)]
    stack_len = 1

    # Bounded iteration - 100000 should be enough for any reasonable config
    for _ in range(100000):
        if stack_len == 0:
            break

        # Pop from stack
        stack_len -= 1
        entry_type, data, indent = stack[stack_len]
        stack = stack[:stack_len]

        prefix = "  " * indent

        if entry_type == "dict_start":
            # Add dict items to stack in reverse order
            items = list(data.items())
            for i in range(len(items) - 1, -1, -1):
                stack.append(("dict_item", items[i], indent))
            stack_len = len(stack)

        elif entry_type == "dict_item":
            key, value = data
            if type(value) == "dict":
                lines.append(prefix + key + ":")
                stack.append(("dict_start", value, indent + 1))
                stack_len = len(stack)
            elif type(value) == "list":
                lines.append(prefix + key + ":")
                stack.append(("list_start", value, indent + 1))
                stack_len = len(stack)
            else:
                lines.append(prefix + key + ": " + _yaml_value(value, indent))

        elif entry_type == "list_start":
            # Add list items to stack in reverse order
            for i in range(len(data) - 1, -1, -1):
                stack.append(("list_item", data[i], indent))
            stack_len = len(stack)

        elif entry_type == "list_item":
            item = data
            if type(item) == "dict":
                # For dict in list, first key on same line as dash
                dict_items = list(item.items())
                if dict_items:
                    first_key, first_value = dict_items[0]
                    if type(first_value) == "dict":
                        lines.append(prefix + "- " + first_key + ":")

                        # Add remaining dict items first (they come after first_value's children)
                        if len(dict_items) > 1:
                            stack.append(("dict_start", dict(dict_items[1:]), indent + 1))

                        # Then add first_value's dict (processed first due to stack order)
                        stack.append(("dict_start", first_value, indent + 2))
                        stack_len = len(stack)
                    elif type(first_value) == "list":
                        lines.append(prefix + "- " + first_key + ":")
                        if len(dict_items) > 1:
                            stack.append(("dict_start", dict(dict_items[1:]), indent + 1))
                        stack.append(("list_start", first_value, indent + 2))
                        stack_len = len(stack)
                    else:
                        lines.append(prefix + "- " + first_key + ": " + _yaml_value(first_value, indent + 1))
                        if len(dict_items) > 1:
                            stack.append(("dict_start", dict(dict_items[1:]), indent + 1))
                            stack_len = len(stack)
            elif type(item) == "list":
                lines.append(prefix + "-")
                stack.append(("list_start", item, indent + 1))
                stack_len = len(stack)
            else:
                lines.append(prefix + "- " + _yaml_value(item, indent))

    return "\n".join(lines)

def _yaml_value(value, indent = 0):
    """Convert a single value to YAML format.

    Args:
        value: The value to convert.
        indent: Current indentation level (used for multiline strings).

    Returns:
        A YAML string representation of the value.
    """
    if type(value) == "bool":
        return "true" if value else "false"
    elif type(value) == "int":
        return str(value)
    elif type(value) == "string":
        # Handle multiline strings with YAML block scalar syntax
        if "\n" in value:
            # Use literal block scalar |
            lines = value.split("\n")
            block_indent = "  " * (indent + 1)
            indented_lines = [block_indent + line for line in lines]
            return "|\n" + "\n".join(indented_lines)

        # Quote strings that contain special characters or look like other types
        if value == "" or value == "null" or value == "true" or value == "false":
            return '"{}"'.format(value)
        if ":" in value or "#" in value or value.startswith("-") or value.startswith("[") or value.startswith("{"):
            return '"{}"'.format(value.replace("\\", "\\\\").replace('"', '\\"'))
        return value
    elif value == None:
        return "null"
    else:
        return str(value)

def _helm_template_impl(ctx):
    """Implementation of the helm_template rule.

    Runs `helm template` on a chart with optional values files
    and outputs the rendered manifests.
    """
    output = ctx.actions.declare_file(ctx.label.name + ".yaml")
    helm_output = ctx.actions.declare_file(ctx.label.name + "_helm.yaml")
    helm_binary = _get_helm_binary(ctx)

    # Collect all input files
    inputs = ctx.files.chart

    # Build the helm template command arguments
    args = ["template", ctx.attr.release_name]

    # Add the chart directory - find the directory containing Chart.yaml
    chart_dir = None
    for f in ctx.files.chart:
        if f.basename == "Chart.yaml":
            chart_dir = f.dirname
            break

    if not chart_dir:
        fail("Could not find Chart.yaml in chart files: {}".format(
            [f.path for f in ctx.files.chart],
        ))

    # Add namespace if specified
    if ctx.attr.namespace:
        args.extend(["--namespace", ctx.attr.namespace])

    # Add include CRDs flag if specified
    if ctx.attr.include_crds:
        args.append("--include-crds")
    if ctx.attr.skip_tests:
        args.append("--skip-tests")
    if ctx.attr.kube_version:
        args.extend(["--kube-version", ctx.attr.kube_version])

    # Build values file arguments
    values_files = []
    if ctx.file.values:
        values_files.append(ctx.file.values)
        inputs = inputs + [ctx.file.values]

    # Handle values_json by converting to a temporary YAML file
    # This supports full nested structures including lists
    values_json_file = None
    if ctx.attr.values_json:
        values_json_file = ctx.actions.declare_file(ctx.label.name + "_values_json.yaml")
        values_dict = json.decode(ctx.attr.values_json)
        yaml_content = _nested_dict_to_yaml(values_dict)
        ctx.actions.write(
            output = values_json_file,
            content = yaml_content,
        )
        values_files.append(values_json_file)

    # Handle set dict by converting to a temporary YAML file
    # The set dict uses dot-notation keys (e.g., "image.tag": "v1.0.0")
    # which are expanded into nested YAML structure
    set_values_file = None
    if ctx.attr.set:
        set_values_file = ctx.actions.declare_file(ctx.label.name + "_set_values.yaml")
        nested_dict = _expand_dot_notation(ctx.attr.set)
        yaml_content = _nested_dict_to_yaml(nested_dict)
        ctx.actions.write(
            output = set_values_file,
            content = yaml_content,
        )
        values_files.append(set_values_file)

    # Build the shell command
    cmd_parts = [
        "set -euo pipefail",
        'EXECROOT="$PWD"',
        '"$EXECROOT/{helm}" template {release_name} "$EXECROOT/{chart_dir}"'.format(
            helm = helm_binary.path,
            release_name = ctx.attr.release_name,
            chart_dir = chart_dir,
        ),
    ]

    # Add namespace flag
    if ctx.attr.namespace:
        cmd_parts[-1] += ' --namespace "{}"'.format(ctx.attr.namespace)

    # Add include CRDs flag
    if ctx.attr.include_crds:
        cmd_parts[-1] += " --include-crds"
    if ctx.attr.skip_tests:
        cmd_parts[-1] += " --skip-tests"
    if ctx.attr.kube_version:
        cmd_parts[-1] += ' --kube-version "{}"'.format(ctx.attr.kube_version)

    # Add values files
    for vf in values_files:
        cmd_parts[-1] += ' -f "$EXECROOT/{}"'.format(vf.path)

    # Redirect Helm output to a temporary file so we can prepend a Namespace if requested.
    cmd_parts[-1] += ' > "$EXECROOT/{}"'.format(helm_output.path)

    cmd = "\n".join(cmd_parts)

    # Prepare all inputs including generated values files
    all_inputs = list(inputs)
    if values_json_file:
        all_inputs.append(values_json_file)
    if set_values_file:
        all_inputs.append(set_values_file)

    ctx.actions.run_shell(
        inputs = all_inputs,
        tools = [helm_binary],
        outputs = [helm_output],
        command = cmd,
        mnemonic = "HelmTemplate",
        progress_message = "Rendering Helm chart {} as {}".format(
            ctx.attr.chart.label,
            ctx.attr.release_name,
        ),
    )

    if ctx.attr.create_namespace:
        if not ctx.attr.namespace:
            fail("create_namespace requires namespace to be set")
        namespace_file = ctx.actions.declare_file(ctx.label.name + "_namespace.yaml")
        namespace_yaml = (
            "apiVersion: v1\n" +
            "kind: Namespace\n" +
            "metadata:\n" +
            "  name: " + ctx.attr.namespace + "\n"
        )
        ctx.actions.write(
            output = namespace_file,
            content = namespace_yaml,
        )
        ctx.actions.run_shell(
            inputs = [namespace_file, helm_output],
            outputs = [output],
            command = 'cat "$1" "$2" > "$3"',
            arguments = [namespace_file.path, helm_output.path, output.path],
            mnemonic = "HelmTemplateNamespace",
            progress_message = "Prepending namespace for {}".format(ctx.attr.release_name),
        )
    else:
        ctx.actions.run_shell(
            inputs = [helm_output],
            outputs = [output],
            command = 'cat "$1" > "$2"',
            arguments = [helm_output.path, output.path],
            mnemonic = "HelmTemplateFinalize",
            progress_message = "Finalizing Helm chart {}".format(ctx.attr.release_name),
        )

    return [DefaultInfo(files = depset([output]))]

_helm_template = rule(
    implementation = _helm_template_impl,
    attrs = {
        "chart": attr.label(
            mandatory = True,
            allow_files = True,
            doc = "The Helm chart to template (e.g., @kratos//:chart).",
        ),
        "values": attr.label(
            allow_single_file = [".yaml", ".yml"],
            doc = "A YAML values file to pass to helm template.",
        ),
        "values_json": attr.string(
            doc = "JSON-encoded values dict to pass to helm template. Supports full nested structures including lists. Use json.encode() in BUILD files.",
        ),
        "set": attr.string_dict(
            default = {},
            doc = "Values to set using dot-notation keys (e.g., 'image.tag': 'v1.0.0'). Converted to YAML and passed as a values file. Overrides values from the values file.",
        ),
        "release_name": attr.string(
            mandatory = True,
            doc = "The Helm release name.",
        ),
        "namespace": attr.string(
            doc = "The Kubernetes namespace for the release.",
        ),
        "include_crds": attr.bool(
            default = False,
            doc = "Include CRDs in the rendered output.",
        ),
        "skip_tests": attr.bool(
            default = False,
            doc = "Skip rendering Helm test manifests.",
        ),
        "kube_version": attr.string(
            doc = "Kubernetes version to use for Helm rendering (e.g., '1.21.0').",
        ),
        "create_namespace": attr.bool(
            default = False,
            doc = "Prepend a Namespace manifest for the release namespace.",
        ),
        "helm": attr.label(
            executable = True,
            cfg = "exec",
            doc = "Custom helm binary to use instead of the toolchain.",
        ),
    },
    toolchains = [config_common.toolchain_type("@helm.bzl//:toolchain_type", mandatory = False)],
    doc = "Renders a Helm chart using `helm template`.",
)

def helm_template(name, chart, visibility = None, values_starlark = None, **kwargs):
    """Renders a Helm chart using `helm template`.

    This rule runs `helm template` on a chart downloaded via the helm module
    extension and outputs the rendered manifests as a YAML file.

    Args:
        name: The name of the target. Output will be {name}.yaml.
        chart: The Helm chart to template. This should be a reference to a chart
               downloaded via helm.chart(), e.g., "@kratos//:chart" or just "@kratos".
        visibility: Target visibility.
        values_starlark: A Starlark dict of values to pass to helm template.
            This supports full nested structures including lists and dicts.
            Values are converted to YAML and passed as a values file.
        **kwargs: Additional arguments passed to the underlying rule:
            - values: A YAML values file (label, optional).
            - values_json: JSON-encoded values string (optional, prefer values_starlark).
            - set: A dict of values to set using dot-notation (optional).
            - release_name: The Helm release name (required).
            - namespace: The Kubernetes namespace (optional).
            - include_crds: Include CRDs in output (bool, default False).
            - kube_version: Kubernetes version for rendering (string, optional).
            - create_namespace: Prepend a Namespace manifest (bool, default False).

    Example using values_starlark (recommended for complex values):
        helm_template(
            name = "kratos_manifests",
            chart = "@kratos//:chart",
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

    Example using set dict (for simple overrides):
        helm_template(
            name = "kratos_manifests",
            chart = "@kratos//:chart",
            values = "values.yaml",
            set = {
                "replicaCount": "3",
                "image.tag": "v1.0.0",
            },
            release_name = "kratos",
            namespace = "identity",
        )

    Note: The `set` dict uses Helm-style dot-notation for nested values.
    The dict {"image.tag": "v1.0.0", "image.repo": "myrepo"} becomes:
        image:
          tag: v1.0.0
          repo: myrepo

    Values are applied in this order (later overrides earlier):
    1. Chart's default values.yaml
    2. values file (if specified)
    3. values_starlark / values_json (if specified)
    4. set dict (if specified)
    """

    # Normalize chart reference - if just @repo, convert to @repo//:chart
    chart_label = chart
    if not "//" in str(chart):
        chart_label = str(chart) + "//:chart"

    # Convert values_starlark to values_json
    if values_starlark != None:
        if "values_json" in kwargs:
            fail("Cannot specify both values_starlark and values_json")
        kwargs["values_json"] = json.encode(values_starlark)

    _helm_template(
        name = name,
        chart = chart_label,
        visibility = visibility,
        **kwargs
    )
