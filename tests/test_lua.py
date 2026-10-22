"""Runs the Lua tests (tests/lua/run.lua) when lua5.1, luajit or lua is on PATH."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
LUA = next((p for p in (shutil.which(n) for n in ('lua5.1', 'luajit', 'lua')) if p), None)


@unittest.skipUnless(LUA, 'no Lua interpreter (lua5.1, luajit or lua) on PATH')
class LuaTest(unittest.TestCase):
    def test_lua_suite(self):
        run = subprocess.run([LUA, 'tests/lua/run.lua'], cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)


if __name__ == '__main__':
    unittest.main()
