"""Runs the Lua tests (tests/lua/run.lua) with lua5.1, luajit or lua from PATH.

Without a Lua interpreter this fails; set MOTEVE_SKIP_LUA=1 to skip it explicitly."""
import os
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
LUA = next((p for p in (shutil.which(n) for n in ('lua5.1', 'luajit', 'lua')) if p), None)


@unittest.skipIf(os.environ.get('MOTEVE_SKIP_LUA') == '1', 'MOTEVE_SKIP_LUA=1')
class LuaTest(unittest.TestCase):
    def test_lua_suite(self):
        self.assertTrue(LUA, 'no Lua interpreter (lua5.1, luajit or lua) on PATH; set MOTEVE_SKIP_LUA=1 to skip')
        run = subprocess.run([LUA, 'tests/lua/run.lua'], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)


if __name__ == '__main__':
    unittest.main()
