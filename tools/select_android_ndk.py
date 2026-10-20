#!/usr/bin/env python3
"""Select a valid Android NDK already installed on the GitHub runner.

The Flutter-generated build.gradle.kts requests flutter.ndkVersion, which
can trigger a large SDK download and fail if Google serves an invalid zip.
If a complete preinstalled NDK exists, prefer it instead. Otherwise leave
Flutter's default and explicitly report the dependency risk.
"""
from pathlib import Path
import os
import re

root=Path(os.environ.get("ANDROID_SDK_ROOT") or
          os.environ.get("ANDROID_HOME","/usr/local/lib/android/sdk"))
ndk_dir=root/"ndk"
candidates=[]
if ndk_dir.is_dir():
    for version in ndk_dir.iterdir():
        if not version.is_dir():continue
        properties=version/"source.properties"
        clang=version/"toolchains"/"llvm"/"prebuilt"
        if not properties.exists() or not clang.is_dir():continue
        content=properties.read_text(encoding="utf-8",errors="ignore")
        match=re.search(r"Pkg.Revision\s*=\s*([0-9.]+)",content)
        if not match:continue
        label=match.group(1)
        candidates.append((tuple(int(n) for n in label.split(".")),label))
gradle=Path("android/app/build.gradle.kts")
if not gradle.exists():
    raise SystemExit("Android project is missing. Run flutter create first.")
src=gradle.read_text(encoding="utf-8")
if not candidates:
    print("WARNING: no complete preinstalled NDK, using Flutter default.")
    print("NDK root:",ndk_dir)
    raise SystemExit(0)
_,ndk=max(candidates)
needle="ndkVersion = flutter.ndkVersion"
if needle not in src:
    raise SystemExit("Expected Gradle ndkVersion line not found")
gradle.write_text(src.replace(needle,f'ndkVersion = "{ndk}"',1),
                  encoding="utf-8")
print("Using verified installed Android NDK:",ndk)
