import unittest

from check_version import release_version, require_increment


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


if __name__ == "__main__":
    unittest.main()
