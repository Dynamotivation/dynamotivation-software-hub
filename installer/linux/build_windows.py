"""Cross-build the Windows frontend on Linux using Clang, xwin, and Wine."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import urllib.request
import zipfile


ROOT = Path(__file__).resolve().parents[2]
APP = ROOT / "apps/windows"
BUILD = APP / "build/linux-windows"
SDK = Path(os.environ["FLUTTER_ROOT"]).resolve()
SYSROOT = Path(os.environ["WINDOWS_SYSROOT"]).resolve()


def run(*args, cwd=APP):
    subprocess.run([str(arg) for arg in args], cwd=cwd, check=True)


def artifact(relative, destination):
    revision = (SDK / "bin/internal/engine.version").read_text().strip()
    destination.mkdir(parents=True, exist_ok=True)
    # Include the artifact path in the cache name: debug and release archives
    # share their basename.
    archive = BUILD / (relative.replace("/", "-") + "-" + revision + ".zip")
    print(f"Fetching Flutter artifact: {relative}", flush=True)
    if not archive.exists():
        partial = archive.with_suffix(".download")
        urllib.request.urlretrieve(
            f"https://storage.googleapis.com/flutter_infra_release/flutter/{revision}/{relative}",
            partial,
        )
        partial.replace(archive)
    with zipfile.ZipFile(archive) as package:
        package.extractall(destination)


def main():
    if os.name != "posix":
        raise SystemExit("Run this build on Linux.")
    BUILD.mkdir(parents=True, exist_ok=True)
    run(SDK / "bin/flutter", "pub", "get")
    engine = SDK / "bin/cache/artifacts/engine"
    artifact("windows-x64-release/windows-x64-flutter.zip", engine / "windows-x64-release")
    artifact("windows-x64/flutter-cpp-client-wrapper.zip", engine / "windows-x64")
    # Desktop ICU data is platform-independent and belongs to the same engine
    # revision. Windows engine ZIPs do not contain it; reuse the Linux host data.
    shutil.copy2(engine / "linux-x64/icudtl.dat", engine / "windows-x64/icudtl.dat")
    snapshot = engine / "windows-x64-release/gen_snapshot"
    snapshot.write_text('''#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import sys
args = []
for arg in sys.argv[1:]:
    if "=" in arg:
        key, value = arg.split("=", 1)
        if value.startswith("/"):
            value = subprocess.check_output(["winepath", "-w", value], text=True).strip()
        arg = key + "=" + value
    elif arg.startswith("/"):
        arg = subprocess.check_output(["winepath", "-w", arg], text=True).strip()
    args.append(arg)
os.execvp("wine", ["wine", str(Path(__file__).with_name("gen_snapshot.exe")), *args])
''')
    snapshot.chmod(0o755)
    run(SDK / "bin/flutter", "assemble", "--no-version-check",
        "--output=build/cross-assets", "-dTargetPlatform=windows-x64",
        "-dBuildMode=release", "-dTargetFile=lib/main.dart",
        "release_bundle_windows-x64_assets")

    dependencies = json.loads((APP / ".flutter-plugins-dependencies").read_text())
    plugins = dependencies["plugins"]["windows"]
    links = APP / "windows/flutter/ephemeral/.plugin_symlinks"
    links.mkdir(parents=True, exist_ok=True)
    for plugin in plugins:
        link = links / plugin["name"]
        if link.is_symlink():
            link.unlink()
        elif link.exists():
            raise RuntimeError(f"Expected a plugin symlink: {link}")
        link.symlink_to(Path(plugin["path"]), target_is_directory=True)

    # Clang's cl driver is the same compiler binary with a different driver mode.
    compiler = BUILD / "clang-cl"
    compiler.write_text('#!/bin/sh\nexec clang-19 --driver-mode=cl "$@"\n')
    compiler.chmod(0o755)
    toolchain = BUILD / "toolchain.cmake"
    toolchain.write_text(f'''set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)
set(CMAKE_TRY_COMPILE_CONFIGURATION Release)
set(CMAKE_MSVC_RUNTIME_LIBRARY MultiThreaded)
set(CMAKE_C_COMPILER "{compiler}")
set(CMAKE_CXX_COMPILER "{compiler}")
set(CMAKE_C_COMPILER_TARGET x86_64-pc-windows-msvc)
set(CMAKE_CXX_COMPILER_TARGET x86_64-pc-windows-msvc)
set(CMAKE_LINKER lld-link-19)
set(CMAKE_AR llvm-lib-19)
set(CMAKE_RC_COMPILER llvm-rc-19)
set(CMAKE_MT llvm-mt-19)
set(CMAKE_RC_FLAGS_INIT "/I{SYSROOT}/sdk/include/um /I{SYSROOT}/sdk/include/shared")
set(CMAKE_C_FLAGS_INIT "-imsvc {SYSROOT}/crt/include -imsvc {SYSROOT}/sdk/include/ucrt -imsvc {SYSROOT}/sdk/include/um -imsvc {SYSROOT}/sdk/include/shared -imsvc {SYSROOT}/sdk/include/winrt")
set(CMAKE_CXX_FLAGS_INIT "${{CMAKE_C_FLAGS_INIT}}")
set(CMAKE_EXE_LINKER_FLAGS_INIT "/libpath:{SYSROOT}/crt/lib/x86_64 /libpath:{SYSROOT}/sdk/lib/ucrt/x86_64 /libpath:{SYSROOT}/sdk/lib/um/x86_64")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${{CMAKE_EXE_LINKER_FLAGS_INIT}}")
''')
    version = next(line.split(":", 1)[1].strip() for line in
                   (APP / "pubspec.yaml").read_text().splitlines()
                   if line.startswith("version:"))
    run("cmake", "-S", ROOT / "installer/linux/windows", "-B", BUILD / "native",
        "-G", "Ninja", f"-DCMAKE_TOOLCHAIN_FILE={toolchain}",
        "-DCMAKE_BUILD_TYPE=Release", f"-DHUB_ROOT={ROOT}",
        f"-DHUB_VERSION={version}",
        "-DHUB_PLUGINS=" + ";".join(plugin["name"] for plugin in plugins))
    run("cmake", "--build", BUILD / "native", "--parallel", "4")
    bundle = BUILD / "bundle"
    if bundle.exists():
        shutil.rmtree(bundle)
    bundle.mkdir()
    for binary in (BUILD / "native").rglob("*"):
        if (binary.suffix.lower() in {".exe", ".dll"}
                and "CMakeFiles" not in binary.parts and binary.stem != "hub_sign_bridge"):
            shutil.copy2(binary, bundle / binary.name)
    shutil.copy2(engine / "windows-x64-release/flutter_windows.dll", bundle)
    shutil.copytree(APP / "build/cross-assets/flutter_assets", bundle / "data/flutter_assets", dirs_exist_ok=True)
    shutil.copy2(APP / "build/cross-assets/windows/app.so", bundle / "data/app.so")
    shutil.copy2(engine / "windows-x64/icudtl.dat", bundle / "data/icudtl.dat")
    print(f"Windows bundle: {bundle}")


if __name__ == "__main__":
    main()
