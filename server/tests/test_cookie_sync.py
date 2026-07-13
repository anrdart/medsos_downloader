import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SERVER_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SERVER_DIR))

import cookie_sync


class CookieSyncDomainTests(unittest.TestCase):
    def test_bilibili_global_uses_bilibili_tv_domain_without_guessed_keys(self):
        with tempfile.TemporaryDirectory() as directory, \
             patch.object(cookie_sync, "COOKIE_DIR", Path(directory)):
            cookie_sync._write_netscape("bilibili", "SESSDATA=value; bili_jct=csrf")
            lines = (Path(directory) / "bilibili.txt").read_text().splitlines()
        cookie_lines = [line for line in lines if not line.startswith("#")]
        self.assertTrue(cookie_lines)
        self.assertTrue(all(line.startswith(".bilibili.tv\tTRUE\t") for line in cookie_lines))
        self.assertTrue(any("\tSESSDATA\tvalue" in line for line in cookie_lines))
        self.assertTrue(any("\tbili_jct\tcsrf" in line for line in cookie_lines))


if __name__ == "__main__":
    unittest.main()
