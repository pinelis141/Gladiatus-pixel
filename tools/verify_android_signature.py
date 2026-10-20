#!/usr/bin/env python3
"""Verify signature of final release APK and pin the certificate SHA-256.

Fail if apksigner is unavailable, APK is unsigned, contains a different
certificate, or Android signature verification fails. Never publish a
debug-signed artifact by accident.
"""
from __future__ import annotations
import hashlib
import os
from pathlib import Path
import re
import subprocess

APK = Path("build/app/outputs/flutter-apk/app-release.apk")
PIN = Path("tools/expected_release_cert.sha256")
CHECKSUM = APK.parent / "Gladiatus-Pixel-APK-SHA256.txt"


def main() -> None:
    if not APK.is_file() or APK.stat().st_size < 1000000:
        raise SystemExit("APK missing or suspiciously small.")
    expected = PIN.read_text(encoding="ascii").strip().lower()
    if not re.fullmatch(r"[0-9a-f]{64}", expected):
        raise SystemExit("Invalid pinned signing certificate.")
    sdk = Path(os.environ.get("ANDROID_SDK_ROOT") or
               os.environ.get("ANDROID_HOME") or
               "/usr/local/lib/android/sdk")
    tools = sdk / "build-tools"
    builds = sorted((p for p in tools.iterdir() if
                     (p / "apksigner").is_file()),
                    key=lambda p: [int(n) for n in
                                   re.findall(r"\d+", p.name)],
                    reverse=True) if tools.is_dir() else []
    if not builds:
        raise SystemExit("apksigner not found in Android SDK build-tools.")
    result = subprocess.run(
        [str(builds[0] / "apksigner"), "verify",
         "--verbose", "--print-certs", str(APK)],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, check=False)
    if result.returncode != 0:
        raise SystemExit("APK signature verification failed: " +
                         result.stderr[:800])
    fingerprints = re.findall(
        r"Signer #\d+ certificate SHA-256 digest:\s*([0-9a-fA-F]+)",
        result.stdout)
    if len(fingerprints) != 1 or fingerprints[0].lower() != expected:
        raise SystemExit("APK signature does not match pinned certificate.")
    digest = hashlib.sha256(APK.read_bytes()).hexdigest()
    CHECKSUM.write_text(f"{digest}  {APK.name}\n", encoding="ascii")
    print("APK assinatura RSA verificada e SHA-256 do certificado confirmado.")
    print("Certificado (publico):", expected)
    print("APK SHA-256:", digest)


if __name__ == "__main__":
    main()
