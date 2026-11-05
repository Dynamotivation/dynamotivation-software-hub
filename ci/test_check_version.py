import unittest
import os
from pathlib import Path
import tempfile

from check_version import release_version, require_increment, require_release_notes


class VersionGateTest(unittest.TestCase):
    def test_release_version_excludes_flutter_build_number(self):
        self.assertEqual(release_version("name: hub\nversion: 1.2.3+42\n"), "1.2.3")

    def test_missing_or_invalid_release_version_fails(self):
        for manifest in ("name: hub", "version: 1.2", "version: 01.2.3", "version: 1.2.3-rc1"):
            with self.subTest(manifest=manifest), self.assertRaises(ValueError):
                release_version(manifest)

    def test_unchanged_or_lower_version_fails(self):
        for current in ("1.2.3", "1.2.2", "1.1.99", "0.99.99"):
            with self.subTest(current=current), self.assertRaises(ValueError):
                require_increment(current, "1.2.3")

    def test_numeric_increments_pass(self):
        for current in ("1.2.4", "1.3.0", "2.0.0", "1.10.0"):
            with self.subTest(current=current):
                require_increment(current, "1.2.3")

    def test_build_number_only_change_fails(self):
        with self.assertRaises(ValueError):
            require_increment(release_version("version: 1.2.3+2"),
                              release_version("version: 1.2.3+1"))

    def test_release_notes_are_required_and_nonempty(self):
        with tempfile.TemporaryDirectory() as folder:
            oldcwd = os.getcwd()
            os.chdir(folder)
            try:
                os.mkdir("release-notes")
                with self.assertRaises(ValueError):
                    require_release_notes("1.2.3")
                (Path("release-notes") / "1.2.3.md").write_text("\n")
                with self.assertRaises(ValueError):
                    require_release_notes("1.2.3")
                (Path("release-notes") / "1.2.3.md").write_text("- Works.\n")
                self.assertEqual(require_release_notes("1.2.3"),
                                 Path("release-notes") / "1.2.3.md")
            finally:
                os.chdir(oldcwd)


if __name__ == "__main__":
    unittest.main()
