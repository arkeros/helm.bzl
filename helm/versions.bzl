"""Helm version registry with SHA256 hashes."""

DEFAULT_HELM_VERSION = "3.17.0"

# Format: "version-os_arch": ("filename", "sha256")
HELM_VERSIONS = {
    "3.17.0-darwin_amd64": ("helm-v3.17.0-darwin-amd64.tar.gz", "05a04e8e02a56e76598e8d75956abda8a78bf20b5e5bdf5abce5b9b0f2d20255"),
    "3.17.0-darwin_arm64": ("helm-v3.17.0-darwin-arm64.tar.gz", "d1eb016d76e574fe5b86a537c57d5552b3bf3ad4a9a5e7a9f4477ff8a2f019d6"),
    "3.17.0-linux_amd64": ("helm-v3.17.0-linux-amd64.tar.gz", "7ab8273b1bf2cee4bdc0c09a90fbb04148a3cc7b8c4b68283f8ac2a20632390e"),
    "3.17.0-linux_arm64": ("helm-v3.17.0-linux-arm64.tar.gz", "a8f0f980a704a18b0d0621f444b05be8cf1fb78ed51636a8f01f82ea7f877d19"),
    "3.17.0-windows_amd64": ("helm-v3.17.0-windows-amd64.zip", "db9dea0c119e8eceeb6ee2ef59ada4b34cce5d5dd0fce77dcb1635e6ce22f1b5"),
}

def get_helm_url(version, filename):
    """Returns the download URL for a Helm release."""
    return "https://get.helm.sh/{}".format(filename)
