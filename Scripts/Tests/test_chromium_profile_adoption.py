"""Profile migration preserves data and resumes after an interrupted launch."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class ProfileAdoptionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.build = tempfile.TemporaryDirectory(prefix="zee-adoption-tests-")
        cls.addClassCleanup(cls.build.cleanup)
        source = Path(cls.build.name) / "adopt.cc"
        source.write_text('''#include <iostream>
#include "ZeeEngines/Chromium/Overlay/chrome/app/zee_user_data_dir.h"
int main(int argc, char** argv) {
  if (argc != 2) return 64;
  std::cout << badge::AdoptProductUserDataDirectory(argv[1]);
}
''')
        cls.executable = Path(cls.build.name) / "adopt"
        subprocess.run([shutil.which("clang++") or "c++", "-std=c++20", "-I", str(ROOT),
                        str(source), "-o", str(cls.executable)], check=True, capture_output=True)

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="zee-adoption-home-")
        self.addCleanup(self.directory.cleanup)
        self.home = Path(self.directory.name)
        self.previous = self.home / "Library/Application Support/Chromium"
        self.preferred = self.home / "Library/Application Support/Zee/Chromium"
        self.previous.mkdir(parents=True)
        self.preferred.mkdir(parents=True)

    def profile(self, root, name, contents="saved cookies"):
        profile = root / name
        profile.mkdir()
        (profile / "Cookies").write_text(contents)
        return profile

    def adopt(self, succeeds=True):
        result = subprocess.run([str(self.executable), str(self.home)], capture_output=True, text=True)
        if succeeds:
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, str(self.preferred))
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def test_empty_destination_from_interrupted_launch_does_not_hide_existing_profiles(self):
        self.profile(self.previous, "Zee-A")
        self.profile(self.previous, "Zee-B")
        self.profile(self.previous, "Default", "other browser")
        self.adopt()
        record = (self.preferred / "Zee Adoption").read_text()
        self.assertEqual(record.splitlines(), [str(self.previous), "Zee-A", "Zee-B"])
        self.assertEqual((self.preferred / "Zee-A/Cookies").read_text(), "saved cookies")
        self.assertEqual((self.preferred / "Zee-B/Cookies").read_text(), "saved cookies")
        self.assertEqual((self.previous / "Default/Cookies").read_text(), "other browser")
        self.adopt()
        self.assertEqual((self.preferred / "Zee Adoption").read_text(), record)

    def test_partial_move_resumes_from_the_durable_record(self):
        self.profile(self.preferred, "Zee-A", "already moved")
        self.profile(self.previous, "Zee-B", "waiting")
        (self.preferred / "Zee Adoption").write_text(f"{self.previous}\nZee-A\nZee-B\n")
        self.adopt()
        self.assertEqual((self.preferred / "Zee-A/Cookies").read_text(), "already moved")
        self.assertEqual((self.preferred / "Zee-B/Cookies").read_text(), "waiting")

    def test_conflicting_profiles_stop_without_overwriting_either_copy(self):
        self.profile(self.previous, "Zee-A", "old")
        self.profile(self.preferred, "Zee-A", "new")
        self.adopt(succeeds=False)
        self.assertEqual((self.previous / "Zee-A/Cookies").read_text(), "old")
        self.assertEqual((self.preferred / "Zee-A/Cookies").read_text(), "new")
        self.assertTrue((self.preferred / "Zee Adoption").exists())


if __name__ == "__main__":
    unittest.main()
