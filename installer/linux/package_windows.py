"""Sign a cross-built Windows bundle and compile signed Inno Setup on Linux."""

import base64
import hashlib
import os
from pathlib import Path
import secrets
import socketserver
import subprocess
import sys
import tempfile
import threading
import urllib.request

from sign_file import sign


ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "apps/windows/build/linux-windows"


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True)


def main():
    # Fail before downloading tools or compiling anything if signing is absent.
    pfx = os.environ.get("SIGNING_CERT_PFX_BASE64")
    password = os.environ.get("SIGNING_CERT_PASSWORD")
    if not pfx or not password:
        raise SystemExit("Both signing secrets are required; unsigned output is forbidden.")
    BUILD.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="signing-", dir=BUILD) as temp:
        secure = Path(temp)
        secure.chmod(0o700)
        certificate = secure / "certificate.pfx"
        certificate.write_bytes(base64.b64decode(pfx, validate=True))
        password_file = secure / "password"
        password_file.write_text(password)
        certificate.chmod(0o600)
        password_file.chmod(0o600)
        os.environ["SIGNING_PFX_PATH"] = str(certificate)
        os.environ["SIGNING_PASSWORD_PATH"] = str(password_file)
        trust = secure / "trust.pem"
        run("openssl", "pkcs12", "-in", certificate, "-passin", f"file:{password_file}",
            "-nokeys", "-clcerts", "-out", trust)
        # The existing publisher cert is self-signed. Explicitly trust that
        # certificate for integrity checks and the system roots for timestamping.
        with trust.open("ab") as output:
            output.write(Path("/etc/ssl/certs/ca-certificates.crt").read_bytes())
        os.environ["SIGNING_CA_PATH"] = str(trust)
        bundle = BUILD / "bundle"
        binaries = sorted(path for path in bundle.rglob("*")
                          if path.suffix.lower() in {".exe", ".dll"})
        if not binaries or not (bundle / "dynamotivation_software_hub.exe").is_file():
            raise SystemExit("The cross-built Windows bundle is missing.")
        for binary in binaries:
            sign(binary)

        tools = BUILD / "inno"
        compiler = tools / "app/ISCC.exe"
        if not compiler.exists():
            installer = BUILD / "innosetup-5.6.1-unicode.exe"
            urllib.request.urlretrieve(
                "https://files.jrsoftware.org/is/5/innosetup-5.6.1-unicode.exe", installer)
            expected = "27d49e9bc769e9d1b214c153011978db90dc01c2acd1ddcd9ed7b3fe3b96b538"
            if hashlib.sha256(installer.read_bytes()).hexdigest() != expected:
                raise SystemExit("Inno Setup download hash mismatch.")
            run("innoextract", "--silent", "--output-dir", tools, installer)
        version = next(line.split(":", 1)[1].strip().split("+")[0]
                       for line in (ROOT / "apps/windows/pubspec.yaml").read_text().splitlines()
                       if line.startswith("version:"))
        source = subprocess.check_output(["winepath", "-w", str(bundle)], text=True).strip()
        iss = subprocess.check_output(
            ["winepath", "-w", str(ROOT / "installer-toolkit/setup/software-hub.iss")],
            text=True).strip()
        token = secrets.token_hex(32)

        class SignRequest(socketserver.StreamRequestHandler):
            def handle(self):
                self.connection.settimeout(180)
                if self.rfile.readline(256).decode().strip() != token:
                    self.wfile.write(b"NO\n")
                    return
                filename = self.rfile.readline(32768).decode().strip()
                try:
                    sign(filename)
                    self.wfile.write(b"OK\n")
                except Exception as error:
                    print(f"Signing callback failed: {error}", flush=True)
                    self.wfile.write(b"NO\n")

        # The PE bridge returns nonzero unless the Linux signer completes and
        # verifies the signature. Inno also signs the uninstaller and temporary
        # setup copies through this same callback.
        with socketserver.TCPServer(("127.0.0.1", 0), SignRequest) as server:
            os.environ["HUB_SIGN_PORT"] = str(server.server_address[1])
            os.environ["HUB_SIGN_TOKEN"] = token
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            bridge = subprocess.check_output(
                ["winepath", "-w", str(BUILD / "native/hub_sign_bridge.exe")],
                text=True).strip()
            try:
                run("wine", compiler, f"/DAppVersion={version}", f"/DSourceDir={source}",
                    f'/Sdyn=$q{bridge}$q $f', iss)
            finally:
                server.shutdown()
                thread.join()
        setup = ROOT / f"dist/Dynamotivation-Software-Hub-Setup-{version}.exe"
        run("osslsigncode", "verify", "-CAfile", trust, "-in", setup)
        digest = hashlib.sha256(setup.read_bytes()).hexdigest()
        setup.with_suffix(".exe.sha256").write_text(f"{digest}  {setup.name}\n")


if __name__ == "__main__":
    main()
