"""Require a new Windows release version before a PR or main push can pass."""

import os
from pathlib import Path
import re
import subprocess


MANIFEST = "apps/windows/pubspec.yaml"


def release_version(manifest):
    match = re.search(r"^version:\s*(\d+\.\d+\.\d+)(?:\+\d+)?\s*$", manifest, re.MULTILINE)
    if not match:
        raise ValueError("Windows version must be MAJOR.MINOR.PATCH, optionally followed by +BUILD.")
    version = match[1]
    if any(str(int(part)) != part for part in version.split(".")):
        raise ValueError("Version components must not contain leading zeroes.")
    return version


def require_increment(current, previous):
    if tuple(map(int, current.split("."))) <= tuple(map(int, previous.split("."))):
        raise ValueError(
            f"Windows release version {current} must be greater than base version {previous}. "
            "Increment apps/windows/pubspec.yaml; changing only +BUILD is insufficient."
        )


def main():
    version = release_version(Path(MANIFEST).read_text())
    base = os.environ.get("BASE_SHA", "")
    if base:
        if not re.fullmatch(r"[0-9a-fA-F]{40}", base) or set(base) == {"0"}:
            raise ValueError("A valid base commit is required for the version comparison.")
        manifest = subprocess.check_output(["git", "show", f"{base}:{MANIFEST}"], text=True)
        require_increment(version, release_version(manifest))
    elif os.environ.get("GITHUB_EVENT_NAME") != "workflow_dispatch":
        raise ValueError("The version comparison base is missing.")
    print(f"Release version: {version}")
    if output := os.environ.get("GITHUB_OUTPUT"):
        with open(output, "a", encoding="utf-8") as stream:
            stream.write(f"version={version}\ntag=v{version}\n")


if __name__ == "__main__":
    main()
