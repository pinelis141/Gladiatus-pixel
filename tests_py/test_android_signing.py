"""Release signer regression tests without access to production secrets."""
import base64
import importlib.util
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1] / "tools/configure_android_signing.py"
spec = importlib.util.spec_from_file_location("android_signing", SOURCE)
signer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(signer)
PIN = "74ea35c6b35690ab025343b42a046b18cd4ebdb08fecb6fd8e99cc72472187f6"
PASS = "A" * 32
GRADLE = """plugins {
    id("com.android.application")
}

android {
    namespace = "com.roma.gladiatus.gladiatus_pixel"
    signingConfigs {
        getByName("debug") {}
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
"""


class TestSigning(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        root = Path(self.temp.name)
        self.gradle = root / "android/app/build.gradle.kts"
        self.gradle.parent.mkdir(parents=True)
        self.gradle.write_text(GRADLE)
        self.keystore = root / "android/gladiatus_release.p12"
        self.props = root / "android/key.properties"
        self.pin = root / "expected.sha256"
        self.pin.write_text(PIN)
        self.encoded = base64.b64encode(b"PKCS12" * 400).decode("ascii")

    def configure(self, encoded=None, password=PASS):
        return signer.prepare_signing(
            self.gradle, self.keystore, self.props, self.pin,
            self.encoded if encoded is None else encoded, password,
        )

    def test_fails_closed_without_required_secret(self):
        with self.assertRaises(SystemExit):
            self.configure(password=None)
        self.assertFalse(self.keystore.exists())
        self.assertIn('getByName("debug")', self.gradle.read_text())

    def test_rejects_corrupt_base64(self):
        with self.assertRaises(SystemExit):
            self.configure(encoded="not base64!@")
        self.assertFalse(self.props.exists())

    def test_detects_wrong_certificate(self):
        with patch.object(signer.subprocess,"run",
                return_value=SimpleNamespace(returncode=0, stderr="",
                    stdout="SHA256: " + ":".join(["00"]*32))):
            with self.assertRaises(SystemExit):
                self.configure()
        self.assertFalse(self.keystore.exists())
        self.assertFalse(self.props.exists())

    def test_patches_release_and_not_debug_when_fingerprint_matches(self):
        public = ":".join(PIN[i:i+2] for i in range(0,64,2))
        with patch.object(signer.subprocess,"run",
                return_value=SimpleNamespace(
                    returncode=0,stderr="",stdout="SHA256: "+public)):
            self.assertEqual(self.configure(), PIN)
        result = self.gradle.read_text()
        self.assertIn('create("release")', result)
        self.assertIn('signingConfigs.getByName("release")', result)
        self.assertNotIn('signingConfig = signingConfigs.getByName("debug")',
                         result)
        self.assertIn('val signingProperties',result)
        self.assertNotIn(PASS,result)
        self.assertTrue(self.props.exists())
        self.assertTrue(self.keystore.exists())
        self.assertEqual(self.keystore.stat().st_mode & 0o777,0o600)
        with self.assertRaises(SystemExit):
            self.configure()

if __name__ == "__main__":
    unittest.main()
