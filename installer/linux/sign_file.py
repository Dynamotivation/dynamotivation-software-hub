"""Mandatory Authenticode signing, also used by Inno Setup through Wine."""

import os
from pathlib import Path
import subprocess
import sys


def sign(path):
    path = str(path)
    if ":" in path:
        path = subprocess.check_output(["winepath", "-u", path], text=True).strip()
    source = Path(path).resolve(strict=True)
    destination = source.with_name(source.name + ".signed")
    try:
        subprocess.run([
            "osslsigncode", "sign", "-pkcs12", os.environ["SIGNING_PFX_PATH"],
            "-readpass", os.environ["SIGNING_PASSWORD_PATH"], "-h", "sha256",
            "-n", "Dynamotivation Software Hub", "-i", "https://dynamotivation.com/",
            "-ts", "http://timestamp.digicert.com", "-in", str(source),
            "-out", str(destination),
        ], check=True)
        subprocess.run([
            "osslsigncode", "verify", "-CAfile", os.environ["SIGNING_CA_PATH"],
            "-in", str(destination),
        ], check=True)
        destination.replace(source)
    finally:
        destination.unlink(missing_ok=True)


if __name__ == "__main__":
    sign(sys.argv[1])
