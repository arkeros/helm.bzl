"""Helm toolchain definition."""

HelmInfo = provider(
    doc = "Information about the helm binary.",
    fields = {
        "helm_binary": "The helm executable File.",
    },
)

def _helm_toolchain_impl(ctx):
    helm_files = ctx.attr.helm.files.to_list()
    if len(helm_files) == 0:
        fail("helm attribute must provide at least one file")

    helm_binary = helm_files[0]
    helm_info = HelmInfo(helm_binary = helm_binary)

    default_info = DefaultInfo(
        files = depset(helm_files),
        runfiles = ctx.runfiles(files = helm_files),
    )

    template_variables = platform_common.TemplateVariableInfo({
        "HELM_BIN": helm_binary.path,
    })

    toolchain_info = platform_common.ToolchainInfo(
        helm_info = helm_info,
        template_variables = template_variables,
        default = default_info,
    )

    return [default_info, toolchain_info, template_variables]

helm_toolchain = rule(
    implementation = _helm_toolchain_impl,
    attrs = {
        "helm": attr.label(
            mandatory = True,
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
    },
    provides = [DefaultInfo, platform_common.ToolchainInfo, platform_common.TemplateVariableInfo],
)
