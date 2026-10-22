"""Check that STEP_EDITS in Guide.lua turns the 0.7.1 routes into the current ones, so saved step indices stay put."""
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[1]
OLD = '49f25ff47cbdc74bd7f07ba71c4096d2394545dc'  # last commit with the 0.7.1 Guides.lua (STEP_REV 0)


def routes(text):
    out = {}
    for m in re.finditer(r'\{ id = "(\w+)".*?steps = \{\n(.*?)\n  \} \}', text, re.DOTALL):
        out[m.group(1)] = re.findall(r'^\s*(\{k=.*\}),?$', m.group(2), re.MULTILINE)
    return out


old = routes(subprocess.run(['git', 'show', f'{OLD}:MoteveGuide/Guides.lua'], cwd=root, check=True,
                            capture_output=True, text=True).stdout)
new = routes((root / 'MoteveGuide' / 'Guides.lua').read_text(encoding='utf-8'))
lua = (root / 'MoteveGuide' / 'Guide.lua').read_text(encoding='utf-8')
block = re.search(r'local STEP_EDITS = \{\n\s*\[1\] = \{.*?\n(.*?)\n    \},\n\}', lua, re.DOTALL).group(1)
edits = {g: [(op, int(at)) for op, at in re.findall(r'\{ "([+-])", (\d+) \}', body)]
         for g, body in re.findall(r'(\w+) = \{(.*)\},', block)}
assert re.search(r'local STEP_REV = 1\n', lua), 'STEP_REV changed: add the new revision to this check'


def migrate(guide, idx, skip):
    """Same remap as MigrateSteps in Guide.lua."""
    gone = False
    for op, at in edits.get(guide, []):
        if op == '+':
            skip = {i + 1 if i >= at else i for i in skip}
        else:
            skip = {i - 1 if i > at else i for i in skip if i != at}
        if op == '-' and idx == at:
            gone = True
        elif idx > at or (op == '+' and idx == at and not gone):
            idx += 1 if op == '+' else -1
    return idx, skip


checked = 0
for gid, steps in old.items():
    # the edit list, applied as list edits, rebuilds the current route exactly
    rebuilt = [('old', i) for i in range(1, len(steps) + 1)]
    for op, at in edits.get(gid, []):
        if op == '-':
            del rebuilt[at - 1]
        else:
            rebuilt.insert(at - 1, ('new', None))
    assert len(rebuilt) == len(new[gid]), (gid, len(rebuilt), len(new[gid]))
    for pos, (src, i) in enumerate(rebuilt, 1):
        if src == 'old':
            assert steps[i - 1] == new[gid][pos - 1], (gid, i, pos)
    kept = {i: pos for pos, (src, i) in enumerate(rebuilt, 1) if src == 'old'}
    # every kept step keeps its place as the current step and as a manual skip; skips of removed steps are dropped
    for i in range(1, len(steps) + 1):
        idx, skip = migrate(gid, i, {i})
        if i in kept:
            assert (idx, skip) == (kept[i], {kept[i]}), (gid, i, idx, skip)
            checked += 1
        else:
            # the player lands on the next kept step, or on a step inserted in the removed one's place
            nxt = next((kept[j] for j in range(i + 1, len(steps) + 1) if j in kept), len(new[gid]) + 1)
            assert skip == set() and idx <= nxt, (gid, i, idx, skip)
            assert all(rebuilt[p - 1][0] == 'new' for p in range(idx, nxt)), (gid, i, idx)

# a Tauren stuck on the removed Seikwa step, with it skipped, lands on the new accept, which is not skipped
seikwa = next(i for i, s in enumerate(old['tauren'], 1) if 'npc="Seikwa"' in s)
idx, skip = migrate('tauren', seikwa, {seikwa})
assert 'k="a", q=1656' in new['tauren'][idx - 1] and not skip, (idx, skip)
print(f'PASS: STEP_EDITS keeps {checked} saved step positions across {len(old)} routes.')
