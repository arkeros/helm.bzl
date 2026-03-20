"""Helm version registry with SHA256 hashes."""

DEFAULT_HELM_VERSION = "3.17.0"

# Format: "version-os_arch": ("filename", "sha256")
HELM_VERSIONS = {
    "3.17.0-darwin_amd64": ("helm-v3.17.0-darwin-amd64.tar.gz", "0d5fd51cf51eb4b9712d52ecd8f2a3cd865680595cca57db38ee01802bd466ea"),
    "3.17.0-darwin_arm64": ("helm-v3.17.0-darwin-arm64.tar.gz", "5db292c69ba756ddbf139abb623b02860feef15c7f1a4ea69b77715b9165a261"),
    "3.17.0-linux_amd64": ("helm-v3.17.0-linux-amd64.tar.gz", "fb5d12662fde6eeff36ac4ccacbf3abed96b0ee2de07afdde4edb14e613aee24"),
    "3.17.0-linux_arm64": ("helm-v3.17.0-linux-arm64.tar.gz", "c4d4be8e80082b7eaa411e3e231d62cf05d01cddfef59b0d01006a7901e11ee4"),
    "3.17.0-windows_amd64": ("helm-v3.17.0-windows-amd64.zip", "db9dea0c119e8eceeb6ee2ef59ada4b34cce5d5dd0fce77dcb1635e6ce22f1b5"),
}

def get_helm_url(version, filename):
    """Returns the download URL for a Helm release."""
    return "https://get.helm.sh/{}".format(filename)
