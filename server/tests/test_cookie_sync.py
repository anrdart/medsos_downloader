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

    def test_meta_platforms_require_complete_auth_cookie_sets(self):
        incomplete = {
            "instagram": "sessionid=s",
            "facebook": "c_user=1",
        }
        for platform, cookies in incomplete.items():
            with self.subTest(platform=platform), self.assertRaises(cookie_sync.HTTPException) as error:
                cookie_sync.set_cookies(
                    cookie_sync.CookiePayload(platform=platform, cookies=cookies),
                    cookie_sync.API_KEY,
                )
            self.assertEqual(error.exception.status_code, 400)

    def test_complete_instagram_cookie_set_is_accepted(self):
        with tempfile.TemporaryDirectory() as directory, \
             patch.object(cookie_sync, "COOKIE_DIR", Path(directory)), \
             patch.object(cookie_sync, "COOKIE_PATH", Path(directory) / "cookies.json"), \
             patch.object(cookie_sync, "_restart_cobalt", return_value=False):
            response = cookie_sync.set_cookies(
                cookie_sync.CookiePayload(
                    platform="instagram",
                    cookies="sessionid=s; ds_user_id=1; csrftoken=c",
                ),
                cookie_sync.API_KEY,
            )
        self.assertEqual(response["status"], "ok")

    def test_rejects_netscape_control_character_injection(self):
        with self.assertRaises(ValueError):
            cookie_sync._cookie_pairs("sessionid=s; name=value\n.example\tTRUE")


if __name__ == "__main__":
    unittest.main()
