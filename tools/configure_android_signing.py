#!/usr/bin/env python3
"""Configure deterministic Android release signing; never use debug signing.

Run only after flutter create. The keystore bytes and password must come
from private GitHub Actions secrets. No private signing material belongs
in git, logs, PR artifacts, or an unsigned fallback APK.
"""
from __future__ import annotations
import base64
import binascii
import os
from pathlib import Path
import re
import subprocess
import sys

ALIAS = "gladiatus_release"
CERT_PIN = Path("tools/expected_release_cert.sha256")
KEYSTORE = Path("android/gladiatus_release.p12")
PROPERTIES = Path("android/key.properties")
GRADLE = Path("android/app/build.gradle.kts")


def fail(reason: str) -> None:
    raise SystemExit("ANDROID RELEASE SIGNING BLOCKED: " + reason)


def prepare_signing(gradle_file: Path, keystore_file: Path,
                    property_file: Path, pin_file: Path,
                    encoded: str | None, password: str | None) -> str:
    if not encoded or not password:
        fail("Configure os secrets GLADIATUS_KEYSTORE_BASE64 e "
             "GLADIATUS_KEYSTORE_PASSWORD em Settings > Secrets and "
             "variables > Actions. APK debug nao sera publicado.")
    if not re.fullmatch(r"[A-Za-z0-9_-]{16,128}", password):
        fail("A senha deve conter 16-128 caracteres alfanumericos, '-' ou '_'.")
    try:
        data = base64.b64decode(encoded.strip(), validate=True)
    except (binascii.Error, ValueError) as exc:
        fail("GLADIATUS_KEYSTORE_BASE64 invalido. Confira o arquivo enviado.")
    if not (1000 <= len(data) <= 100000):
        fail("Tamanho de PKCS12 inesperado.")
    if not gradle_file.exists():
        fail("Gradle nao encontrado. Execute flutter create primeiro.")
    if not pin_file.exists():
        fail("Fingerprint do certificado nao foi configurado.")

    source = gradle_file.read_text(encoding="utf-8")
    debug_config = 'signingConfig = signingConfigs.getByName("debug")'
    if debug_config not in source or "    buildTypes {" not in source:
        fail("Estrutura Gradle inesperada: recusando assinatura incorreta.")
    if 'create("release")' in source:
        fail("Configuracao release duplicada; revise gradle.")
    expected = pin_file.read_text(encoding="ascii").strip().lower()
    if not re.fullmatch("[0-9a-f]{64}", expected):
        fail("Fingerprint SHA-256 pinado invalido.")
    keystore_file.parent.mkdir(parents=True, exist_ok=True)
    # The keystore and properties are created only on the CI runner.
    keystore_file.write_bytes(data)
    keystore_file.chmod(0o600)
    result = subprocess.run(
        ["keytool", "-list", "-v", "-storetype", "PKCS12",
         "-keystore", str(keystore_file), "-alias", ALIAS,
         "-storepass:env", "GLADIATUS_KEYSTORE_PASSWORD"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, env={**os.environ, "GLADIATUS_KEYSTORE_PASSWORD": password},
        check=False)
    if result.returncode != 0:
        keystore_file.unlink(missing_ok=True)
        fail("PKCS12 nao abriu, senha/alias incorretos.")
    match = re.search(r"SHA256:\s*([0-9A-Fa-f:]+)", result.stdout)
    found = match.group(1).replace(":", "").lower() if match else None
    if found != expected:
        keystore_file.unlink(missing_ok=True)
        fail("Certificado diferente do fingerprint pinado. "
             "Nao publique uma atualizacao com outra chave.")

    property_file.write_text(
        f"storePassword={password}\n"
        f"keyPassword={password}\n"
        f"keyAlias={ALIAS}\n",
        encoding="utf-8")
    property_file.chmod(0o600)

    # Generated Flutter Android Gradle DSL is Kotlin. Both key material and
    # password live outside of the Gradle source file.
    block = """
    signingConfigs {
        create("release") {
            storeFile = rootProject.file("gladiatus_release.p12")
            storePassword = signingProperties.getProperty("storePassword")
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")
        }
    }
    buildTypes {"""
    source = source.replace("    buildTypes {", block, 1)
    source = source.replace(debug_config,
                            'signingConfig = signingConfigs.getByName("release")', 1)
    # Top-level Kotlin DSL declarations must follow the plugins {} block.
    top = """
val signingProperties = java.util.Properties().apply {
    rootProject.file("key.properties").inputStream().use { load(it) }
}

"""
    anchor = "\nandroid {"
    if anchor not in source:
        fail("Bloco android Gradle nao encontrado.")
    source = source.replace(anchor, "\n" + top + "android {", 1)
    gradle_file.write_text(source, encoding="utf-8")
    print("Release signing configurado com fingerprint fixo:",
          expected)
    return expected


if __name__ == "__main__":
    prepare_signing(
        GRADLE, KEYSTORE, PROPERTIES, CERT_PIN,
        os.environ.get("GLADIATUS_KEYSTORE_BASE64"),
        os.environ.get("GLADIATUS_KEYSTORE_PASSWORD"),
    )
