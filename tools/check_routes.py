"""Check route data in Guides.lua against the Classic-style client (## Interface: 16001)."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
path = Path(sys.argv[1]) if len(sys.argv) > 1 else root / 'MoteveGuide' / 'Guides.lua'
text = path.read_text(encoding='utf-8')

# Flight points that exist in the target client, by uiMapID and flight master as named in the data.
# Razor Hill, Brill and Bloodhoof Village only got a flight master after Classic.
CLASSIC_FP = {
    (1413, 'Sikwa'),        # The Crossroads
    (1413, 'Reggifuz'),     # Ratchet
    (1413, 'Kelsuwa'),      # Camp Taurajo
    (1442, 'Gereck'),       # Sun Rock Retreat
    (1440, 'Qeeju'),        # Splintertree Post
    (1441, 'Awenasa'),      # Freewind Post
    (1421, 'Sarah Goode'),  # The Sepulcher
    (1456, 'Bulrug'),       # Thunder Bluff
}


def field(step, name):
    m = re.search(name + r'=("([^"]*)"|[-\d.]+)', step)
    return m and (m.group(2) if m.group(2) is not None else m.group(1))


routes = {}
for m in re.finditer(r'\{ id = "(\w+)".*?steps = \{\n(.*?)\n  \} \}', text, re.DOTALL):
    routes[m.group(1)] = re.findall(r'^\s*(\{k=.*\}),?$', m.group(2), re.MULTILINE)
assert {'orctroll', 'tauren', 'undead'} <= routes.keys(), routes.keys()

fps = 0
for rid, steps in routes.items():
    for step in steps:
        if field(step, 'k') == 'fp':
            fps += 1
            key = (int(field(step, 'm')), field(step, 'npc'))
            assert key in CLASSIC_FP, f'{rid}: flight path not in the target client: {key}'

tauren = routes['tauren']


def index(k, q):
    found = [i for i, s in enumerate(tauren) if field(s, 'k') == k and field(s, 'q') == str(q)]
    assert len(found) == 1, (k, q, found)
    return found[0]


# 'A Task Unfinished' is picked up on the road out of Camp Narache and handed in on arrival in Bloodhoof.
accept, turnin = index('a', 1656), index('t', 1656)
assert index('a', 763) < accept < turnin < index('t', 763), (accept, turnin)
assert int(field(tauren[accept], 'el')) <= 5 and int(field(tauren[turnin], 'el')) <= 5
assert 62 < float(field(tauren[accept], 'y')) < 76, 'accept must be on the Narache -> Bloodhoof road'
assert not any(field(s, 'k') == 'fp' and field(s, 'm') == '1412' for s in tauren), 'Mulgore has no Classic flight master'
print(f'PASS: {len(routes)} routes; {fps} flight path steps, all in the target client; A Task Unfinished on the Bloodhoof road.')
