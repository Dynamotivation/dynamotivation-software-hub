"""Exercise publication against a local Git remote and a recording GitHub stub."""

import hashlib
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(os.name == "posix", "Release script runs on Linux")
class ReleaseTest(unittest.TestCase):
    def setUp(self):
        (ROOT / "build").mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=ROOT / "build")
        self.addCleanup(self.temp.cleanup)
        self.folder = Path(self.temp.name)
        self.repo = self.folder / "repo"
        self.repo.mkdir()
        self.git("init", "--bare", str(self.folder / "remote.git"))
        self.git("init", "-b", "main")
        self.git("config", "user.name", "Release Test")
        self.git("config", "user.email", "release-test@example.invalid")
        (self.repo / "file").write_text("first")
        self.git("add", ".")
        self.git("commit", "-m", "first")
        self.sha = self.git("rev-parse", "HEAD").strip()
        (self.repo / "file").write_text("second")
        self.git("commit", "-am", "second")
        self.git("remote", "add", "origin", str(self.folder / "remote.git"))
        (self.repo / "dist").mkdir()
        self.setup = self.repo / "dist/dynamotivation-software-hub-setup-1.2.3.exe"
        self.setup.write_bytes(b"signed-build-fixture")
        self.setup.with_suffix(".exe.sha256").write_text(
            f"{hashlib.sha256(self.setup.read_bytes()).hexdigest()}  {self.setup.name}\n")
        tools = self.folder / "bin"
        tools.mkdir()
        gh = tools / "gh"
        gh.write_text('''#!/usr/bin/env python3
import os
from pathlib import Path
import sys
state=Path(os.environ['GH_TEST_STATE'])
args=sys.argv[1:]
with Path(str(state)+'.log').open('a') as log:
    log.write(' '.join(args)+'\\n')
if args[:2]==['release','view']:
    if not state.exists(): raise SystemExit(1)
    print('123' if 'databaseId' in args else ('true' if state.read_text()=='draft' else 'false'))
elif args[:2]==['release','create']:
    state.write_text('draft')
elif args[:2]==['release','upload']:
    if state.read_text()!='draft': raise SystemExit(2)
elif args[0]=='api':
    state.write_text('published')
else: raise SystemExit(3)
''')
        gh.chmod(0o755)
        self.state = self.folder / "release-state"
        self.env = dict(os.environ, PATH=f"{tools}:{os.environ['PATH']}",
                        GH_TEST_STATE=str(self.state), GITHUB_EVENT_NAME="push",
                        GITHUB_REF="refs/heads/main", GITHUB_SHA=self.sha,
                        GITHUB_REPOSITORY="fixture/repository", RELEASE_VERSION="1.2.3")

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.repo, text=True,
                                       stderr=subprocess.DEVNULL)

    def publish(self):
        return subprocess.run(["bash", str(ROOT / "ci/publish_release.sh")],
                              cwd=self.repo, env=self.env, capture_output=True, text=True)

    def test_tags_exact_push_commit_and_publishes_after_upload(self):
        result = self.publish()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.git("rev-parse", "v1.2.3^{commit}").strip(), self.sha)
        self.assertEqual(self.state.read_text(), "published")
        log = Path(str(self.state) + ".log").read_text()
        self.assertIn(f"--target {self.sha}", log)
        self.assertLess(log.index("release upload"), log.index("api --method PATCH"))

    def test_rejects_non_main_runs(self):
        self.env["GITHUB_REF"] = "refs/heads/ci/test"
        self.assertNotEqual(self.publish().returncode, 0)
        self.assertFalse(self.state.exists())
        self.assertEqual(self.git("tag").strip(), "")

    def test_never_moves_an_existing_tag(self):
        self.git("tag", "v1.2.3", "HEAD")
        self.assertNotEqual(self.publish().returncode, 0)
        self.assertEqual(self.git("rev-parse", "v1.2.3").strip(), self.git("rev-parse", "HEAD").strip())
        self.assertFalse(self.state.exists())

    def test_rejects_a_corrupt_artifact_before_tagging(self):
        self.setup.write_bytes(b"corrupt")
        self.assertNotEqual(self.publish().returncode, 0)
        self.assertEqual(self.git("tag").strip(), "")

    def test_rerun_preserves_an_existing_published_release(self):
        self.assertEqual(self.publish().returncode, 0)
        log = Path(str(self.state) + ".log")
        log.write_text("")
        self.assertEqual(self.publish().returncode, 0)
        self.assertNotIn("release upload", log.read_text())


if __name__ == "__main__":
    unittest.main()
