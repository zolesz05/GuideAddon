"""Convert the free RestedXP WoW Forever 1-20/22 guides into MoteveGuide/RXPRoutes.lua.

Input: the allowlisted Guides/forever files of RestedXP/RXPGuides, copied with their
LICENSE to tools/rxp_src/<RXP_SHA>/, so the output only depends on the files in this repo.
Run: python3 tools/import_rxp.py [--out PATH]
"""
from pathlib import Path
import argparse
import re
import sys

RXP_SHA = '0eed3ea65746da13535b8e71b2070a2690ae0ec6'
ROOT = Path(__file__).resolve().parents[1]
SRC_DIR = ROOT / 'tools' / 'rxp_src' / RXP_SHA
OUT = ROOT / 'MoteveGuide' / 'RXPRoutes.lua'

# The free Forever speedrun guides (1-20 Alliance, 1-22 Horde) and the Mage variants.
ALLOWED_FILES = (
    'Horde-1-12_Mulgore.lua',
    'Horde-01-12_Durotar.lua',
    'Horde-01-14_Undead.lua',
    'Horde-12-22_Barrens.lua',
    'Alliance-1-13_Human.lua',
    'Alliance-1-14_DwarfGnome.lua',
    'Alliance-1-10_NightElf.lua',
    'Alliance-11-20.lua',
    'Horde-Mage-12-21.lua',
    'Alliance-Mage-1-12.lua',
    'Alliance-Mage-12-21.lua',
    'Alliance-ADV-AoE-Mage-1-22.lua',
)


class RXPError(Exception):
    pass


# ---------------------------------------------------------------------------
# Races, classes and conditions ("<< Orc Hunter/Troll !Warrior")
# ---------------------------------------------------------------------------
# Same bits as RACEBIT / CLASSBIT in MoteveGuide/Guide.lua.
RACEBIT = {'HUMAN': 1, 'ORC': 2, 'DWARF': 4, 'NIGHTELF': 8, 'UNDEAD': 16, 'TAUREN': 32, 'GNOME': 64, 'TROLL': 128}
CLASSBIT = {'WARRIOR': 1, 'PALADIN': 2, 'HUNTER': 4, 'ROGUE': 8, 'PRIEST': 16, 'SHAMAN': 64, 'MAGE': 128,
            'WARLOCK': 256, 'DRUID': 1024}
RACES = tuple(RACEBIT)
CLASSES = tuple(CLASSBIT)
ALL = frozenset((r, c) for r in RACES for c in CLASSES)
FACTION_RACES = {'Horde': ('ORC', 'UNDEAD', 'TAUREN', 'TROLL'), 'Alliance': ('HUMAN', 'DWARF', 'NIGHTELF', 'GNOME')}
RACE_TOKENS = {'Human': 'HUMAN', 'Orc': 'ORC', 'Dwarf': 'DWARF', 'NightElf': 'NIGHTELF', 'Undead': 'UNDEAD',
               'Tauren': 'TAUREN', 'Gnome': 'GNOME', 'Troll': 'TROLL'}
CLASS_TOKENS = {c.capitalize(): c for c in CLASSES}
TOKEN_TYPOS = {'Maget': 'Mage', 'Dawrf': 'Dwarf'}
# Forever races the addon has no RACEBIT for: steps only for them are left out.
UNKNOWN_RACES = {'Skyborne'}
# WoW Forever is treated as Classic Era, not Season of Discovery / Mastery; "skip" is never shown.
FLAGS = {'era': True, 'sod': False, 'som': False, 'skip': False}
SEASON = 0
XP_RATE = 1.0


def token_set(token, where):
    name = token.lstrip('!')
    name = TOKEN_TYPOS.get(name, name)
    if name in RACE_TOKENS:
        s = {p for p in ALL if p[0] == RACE_TOKENS[name]}
    elif name in CLASS_TOKENS:
        s = {p for p in ALL if p[1] == CLASS_TOKENS[name]}
    elif name in FACTION_RACES:
        s = {p for p in ALL if p[0] in FACTION_RACES[name]}
    elif name in UNKNOWN_RACES:
        s = set()
    elif name.lower() in FLAGS:
        s = set(ALL) if FLAGS[name.lower()] else set()
    else:
        raise RXPError(f'{where}: unknown condition {token!r}')
    return frozenset(ALL - s if token.startswith('!') else s)


def condition(expr, where):
    """RXP condition: '/' separates alternatives, spaces join terms, '!' negates."""
    expr = expr.strip()
    if not expr:
        return ALL
    out = set()
    for alt in expr.split('/'):
        s = ALL
        for token in alt.split():
            s &= token_set(token, where)
        out |= s
    return frozenset(out)


# ---------------------------------------------------------------------------
# Maps: zone names and the world -> zone coordinate frames (UiMap / UiMapAssignment 1.15.9)
# ---------------------------------------------------------------------------
ZONE_IDS = {
    'Durotar': 1411, 'Mulgore': 1412, 'The Barrens': 1413, 'Alterac Mountains': 1416, 'Arathi Highlands': 1417,
    'Badlands': 1418, 'Blasted Lands': 1419, 'Tirisfal Glades': 1420, 'Silverpine Forest': 1421,
    'Western Plaguelands': 1422, 'Eastern Plaguelands': 1423, 'Hillsbrad Foothills': 1424, 'The Hinterlands': 1425,
    'Dun Morogh': 1426, 'Searing Gorge': 1427, 'Burning Steppes': 1428, 'Elwynn Forest': 1429, 'Deadwind Pass': 1430,
    'Duskwood': 1431, 'Loch Modan': 1432, 'Redridge Mountains': 1433, 'Stranglethorn Vale': 1434,
    'Swamp of Sorrows': 1435, 'Westfall': 1436, 'Wetlands': 1437, 'Teldrassil': 1438, 'Darkshore': 1439,
    'Ashenvale': 1440, 'Thousand Needles': 1441, 'Stonetalon Mountains': 1442, 'Desolace': 1443, 'Feralas': 1444,
    'Dustwallow Marsh': 1445, 'Tanaris': 1446, 'Azshara': 1447, 'Felwood': 1448, "Un'Goro Crater": 1449,
    'Moonglade': 1450, 'Silithus': 1451, 'Winterspring': 1452, 'Stormwind City': 1453, 'Orgrimmar': 1454,
    'Ironforge': 1455, 'Thunder Bluff': 1456, 'Darnassus': 1457, 'Undercity': 1458,
}
# uiMapID: (Region_0, Region_1, Region_3, Region_4, continent instance)
CONTINENTS = (1414, 1415)
ZONE_BOUNDS = {
    1411: (-1716.6666259766, -7249.9995117188, 1808.3332519531, -1962.4998779297, 1),  # Durotar
    1412: (-3697.9165039062, -3089.5832519531, -272.91665649414, 2047.9166259766, 1),  # Mulgore
    1413: (-5143.75, -7510.4165039062, 1612.4998779297, 2622.9165039062, 1),  # The Barrens
    1414: (-11733.299804688, -19733.2109375, 12799.900390625, 17066.599609375, 1),  # Kalimdor
    1415: (-16000, -19199.900390625, 7466.6000976562, 16000, 0),  # Eastern Kingdoms
    1416: (-366.66665649414, -2016.6666259766, 1500, 783.33331298828, 0),  # Alterac Mountains
    1417: (-2533.3332519531, -4466.6665039062, -133.33332824707, -866.66662597656, 0),  # Arathi Highlands
    1418: (-7547.9165039062, -4566.6665039062, -5889.5830078125, -2079.1665039062, 0),  # Badlands
    1419: (-12800, -4591.6665039062, -10566.666015625, -1241.6666259766, 0),  # Blasted Lands
    1420: (824.99993896484, -1485.4166259766, 3837.4997558594, 3033.3332519531, 0),  # Tirisfal Glades
    1421: (-1133.3332519531, -750, 1666.6666259766, 3449.9997558594, 0),  # Silverpine Forest
    1422: (499.99996948242, -3883.3332519531, 3366.6665039062, 416.66665649414, 0),  # Western Plaguelands
    1423: (1218.75, -6056.25, 3799.9997558594, -2185.4165039062, 0),  # Eastern Plaguelands
    1424: (-1733.3332519531, -2133.3332519531, 400, 1066.6666259766, 0),  # Hillsbrad Foothills
    1425: (-1100, -5425, 1466.6666259766, -1575, 0),  # The Hinterlands
    1426: (-7160.4165039062, -3122.9165039062, -3877.0832519531, 1802.0832519531, 0),  # Dun Morogh
    1427: (-7587.4995117188, -2554.1665039062, -6100, -322.91665649414, 0),  # Searing Gorge
    1428: (-8983.3330078125, -3195.8332519531, -7031.2495117188, -266.66665649414, 0),  # Burning Steppes
    1429: (-10254.166015625, -1935.4166259766, -7939.5830078125, 1535.4166259766, 0),  # Elwynn Forest
    1430: (-11533.333007812, -3333.3332519531, -9866.666015625, -833.33331298828, 0),  # Deadwind Pass
    1431: (-11516.666015625, -1866.6666259766, -9716.666015625, 833.33331298828, 0),  # Duskwood
    1432: (-6327.0830078125, -4752.0830078125, -4487.5, -1993.7498779297, 0),  # Loch Modan
    1433: (-10022.916015625, -3741.6665039062, -8575, -1570.8332519531, 0),  # Redridge Mountains
    1434: (-15422.916015625, -4160.4165039062, -11168.75, 2220.8332519531, 0),  # Stranglethorn Vale
    1435: (-11150, -4516.6665039062, -9620.8330078125, -2222.9165039062, 0),  # Swamp of Sorrows
    1436: (-11733.333007812, -483.33331298828, -9400, 3016.6665039062, 0),  # Westfall
    1437: (-4904.1665039062, -4525, -2147.9165039062, -389.58331298828, 0),  # Wetlands
    1438: (8437.5, -1277.0832519531, 11831.25, 3814.5832519531, 1),  # Teldrassil
    1439: (3966.6665039062, -3608.3332519531, 8333.3330078125, 2941.6665039062, 1),  # Darkshore
    1440: (829.16662597656, -4066.6665039062, 4672.9165039062, 1699.9998779297, 1),  # Ashenvale
    1441: (-6899.9995117188, -4833.3330078125, -3966.6665039062, -433.33331298828, 1),  # Thousand Needles
    1442: (-339.58331298828, -1637.4998779297, 2916.6665039062, 3245.8332519531, 1),  # Stonetalon Mountains
    1443: (-2545.8332519531, -262.5, 452.08331298828, 4233.3330078125, 1),  # Desolace
    1444: (-6999.9995117188, -1508.3332519531, -2366.6665039062, 5441.6665039062, 1),  # Feralas
    1445: (-5533.3330078125, -6225, -2033.3332519531, -974.99993896484, 1),  # Dustwallow Marsh
    1446: (-10475, -7118.7495117188, -5875, -218.74998474121, 1),  # Tanaris
    1447: (1960.4166259766, -8347.916015625, 5341.6665039062, -3277.0832519531, 1),  # Azshara
    1448: (3299.9997558594, -4108.3330078125, 7133.3330078125, 1641.6666259766, 1),  # Felwood
    1449: (-8433.3330078125, -3166.6665039062, -5966.6665039062, 533.33331298828, 1),  # Un'Goro Crater
    1450: (6952.0830078125, -3689.5832519531, 8491.666015625, -1381.25, 1),  # Moonglade
    1451: (-8281.25, -945.833984375, -5958.333984375, 2537.5, 1),  # Silithus
    1452: (3799.9997558594, -7416.6665039062, 8533.3330078125, -316.66665649414, 1),  # Winterspring
    1453: (-9175.205078125, 36.70063018799, -8278.8505859375, 1380.9714355469, 0),  # Stormwind City
    1454: (1338.4605712891, -5083.2055664062, 2273.8771972656, -3680.6010742188, 1),  # Orgrimmar
    1455: (-5096.845703125, -1504.2164306641, -4569.2412109375, -713.59136962891, 0),  # Ironforge
    1456: (-1545.8332519531, -527.08331298828, -849.99993896484, 516.66662597656, 1),  # Thunder Bluff
    1457: (9532.5869140625, 1880.0295410156, 10238.31640625, 2938.3627929688, 1),  # Darnassus
    1458: (1237.8411865234, -86.18240356445, 1877.9453125, 873.19262695313, 0),  # Undercity
}


def zone_id(name, where):
    if name not in ZONE_IDS:
        raise RXPError(f'{where}: unknown zone {name!r}')
    return ZONE_IDS[name]


def map_pos(m, wx, wy):
    r0, r1, r3, r4, _ = ZONE_BOUNDS[m]
    return (r4 - wx) / (r4 - r1) * 100, (r3 - wy) / (r3 - r0) * 100


def world_to_map(m, instance, wx, wy, where):
    """World coordinates ('.goto 1412/1,x,y') -> zone percent. A point outside the given map, or on a
    continent map, moves to the smallest zone that contains it."""
    if m not in ZONE_BOUNDS or ZONE_BOUNDS[m][4] != instance:
        raise RXPError(f'{where}: unknown map {m}/{instance}')
    x, y = map_pos(m, wx, wy)
    if m in CONTINENTS or not (0 <= x <= 100 and 0 <= y <= 100):
        inside = []
        for other, b in ZONE_BOUNDS.items():
            ox, oy = map_pos(other, wx, wy)
            if other not in CONTINENTS and b[4] == instance and 0 <= ox <= 100 and 0 <= oy <= 100:
                inside.append(((b[3] - b[1]) * (b[2] - b[0]), other, ox, oy))
        if inside:
            _, m, x, y = min(inside)
    return m, x, y


def number(text, where):
    m = re.match(r'-?\d+(?:\.\d+)?', text)   # one source coordinate reads "-623.92.00"
    if not m:
        raise RXPError(f'{where}: bad number {text!r}')
    return float(m.group())


def parse_goto(args, where):
    parts = [p.strip() for p in args.split(',')]
    if len(parts) < 3:
        raise RXPError(f'{where}: bad .goto {args!r}')
    head = parts[0]
    if '/' in head:
        m, instance = head.split('/')
        return world_to_map(int(m), int(instance), number(parts[1], where), number(parts[2], where), where)
    m = int(head) if head.isdigit() else zone_id(head, where)
    return m, number(parts[1], where), number(parts[2], where)


# ---------------------------------------------------------------------------
# Parsing the RXP guide text
# ---------------------------------------------------------------------------
GUIDE_RE = re.compile(r'RXPGuides\.RegisterGuide\(\[\[(.*?)\]\]\)', re.S)
STEP_RE = re.compile(r'^s?step\b')   # one source line says "sstep"
LEVELS_RE = re.compile(r'^(\d+)-(\d+)\b')

# What each dot command becomes; anything not listed stops the converter.
QUEST_ACTIONS = {'accept', 'turnin', 'complete', 'fp', 'xp'}
NOTE_COMMANDS = {'hs', 'home', 'fly', 'train', 'trainer', 'vendor', 'collect', 'use', 'equip', 'zone', 'subzone',
                 'deathskip', 'abandon'}
QUEST_CONDITIONS = {'isOnQuest', 'isQuestComplete', 'isQuestTurnedIn', 'isQuestAvailable', 'isNotOnQuest',
                    'isQuestNotComplete'}
# Dungeon steps: the guides are #disabledungeons.
DROP_COMMANDS = {'dungeon'}
# Units to kill: their names become the 'mob' list of the step's complete steps.
MOB_COMMANDS = {'mob', 'unitscan'}
IGNORED_COMMANDS = {
    'goto', 'target', 'itemStat', 'itemcount', 'money', 'waypoint', 'zoneskip', 'skill', 'subzoneskip',
    'disablecheckbox', 'cast', 'link', 'line', 'usespell', 'bindlocation', 'cooldown', 'timer', 'destroy',
    'aura', 'group', 'bankdeposit', 'bankwithdraw', 'skipgossip', 'skipgossipid', 'gossipoption', 'bronzetube',
    'maxlevel', 'macro', 'solo', 'addquestitem', 'engrave',
}
KNOWN_COMMANDS = QUEST_ACTIONS | NOTE_COMMANDS | QUEST_CONDITIONS | DROP_COMMANDS | MOB_COMMANDS | IGNORED_COMMANDS
# Directives that do not change whether a step is shown.
NEUTRAL_DIRECTIVES = {'label', 'requires', 'loop', 'sticky', 'optional', 'map', 'hidewindow', 'level', 'softcore',
                      'ah', 'phase', 'era', 'era/som'}


def split_line(raw):
    """'.cmd args >>text << cond --comment' -> (cmd args, text, cond, comment)"""
    line, comment = raw.strip(), ''
    i = line.find('--')
    if i >= 0:
        line, comment = line[:i].rstrip(), line[i + 2:].strip()
    cond = ''
    j = line.rfind('<<')
    if j >= 0:
        line, cond = line[:j].rstrip(), line[j + 2:].strip()
    text = ''
    k = line.find('>>')
    if k >= 0:
        line, text = line[:k].rstrip(), line[k + 2:].strip()
    return line, text, cond, comment


def clean(text):
    text = re.sub(r'\|T[^|]*\|t', '', text)
    text = re.sub(r'\|c(?:RXP_[A-Z]+_|[0-9a-fA-F]{8})', '', text)
    text = text.replace('|r', '').replace('|', '')
    return re.sub(r'\s+', ' ', text).strip()


DIRECTIVE_TYPOS = {'sofcore': 'softcore'}


def directive_shown(name, arg, where):
    name = DIRECTIVE_TYPOS.get(name, name)
    if name in NEUTRAL_DIRECTIVES:
        return True
    if name in ('completewith', 'hardcore', 'ssf', 'som'):
        # background hints, the hardcore branch, self-found and Season of Mastery steps are left out
        return False
    if name == 'season':
        return SEASON in [int(v) for v in arg.split(',')]
    if name == 'xprate':
        m = re.fullmatch(r'([<>]?)([\d.]+)(?:-([\d.]+))?', arg.strip())
        if not m:
            raise RXPError(f'{where}: bad #xprate {arg!r}')
        op, a, b = m.group(1), float(m.group(2)), m.group(3)
        if b:
            return a <= XP_RATE <= float(b)
        return XP_RATE < a if op == '<' else XP_RATE > a if op == '>' else XP_RATE == a
    raise RXPError(f'{where}: unknown directive #{name}')


class Guide:
    def __init__(self, name, cond, nexts, steps, where):
        self.name, self.cond, self.nexts, self.steps, self.where = name, cond, nexts, steps, where
        m = LEVELS_RE.match(name)
        self.level = int(m.group(1)) if m else 1


def parse_guide(body, where):
    header, steps, current = [], [], None
    for n, raw in enumerate(body.splitlines(), 1):
        stripped = raw.strip()
        if STEP_RE.match(stripped):
            current = {'head': stripped, 'lines': [], 'where': f'{where}:{n}'}
            steps.append(current)
        elif current is None:
            header.append(stripped)
        elif stripped and not stripped.startswith('--'):
            current['lines'].append((stripped, f'{where}:{n}'))
    name, cond, nexts = None, '', []
    for line in header:
        if line.startswith('#name '):
            name = line[6:].strip()
        elif line.startswith('#next '):
            body_, _, _, _ = split_line(line[6:])
            nexts += [part.strip() for part in body_.split(';') if part.strip()]
        elif line.startswith('<<'):
            cond = line[2:].strip()
    if not name:
        raise RXPError(f'{where}: guide without #name')
    return Guide(name, cond, nexts, steps, where)


def read_source(name, src_dir=SRC_DIR):
    if name not in ALLOWED_FILES:
        raise RXPError(f'{name}: not in the allowlist of free RestedXP Forever guides')
    return (Path(src_dir) / name).read_text(encoding='utf-8')


def load_guides(src_dir=SRC_DIR):
    extra = sorted(p.name for p in Path(src_dir).glob('*.lua') if p.name not in ALLOWED_FILES)
    if extra:
        raise RXPError(f'not in the allowlist of free RestedXP Forever guides: {", ".join(extra)}')
    guides = {}
    for name in ALLOWED_FILES:
        for i, body in enumerate(GUIDE_RE.findall(read_source(name, src_dir)), 1):
            guide = parse_guide(body, f'{name}#{i}')
            if guide.name in guides:
                raise RXPError(f'{guide.where}: duplicate guide name {guide.name!r}')
            guides[guide.name] = guide
    return guides


def quest_titles(guides):
    titles = {}
    for guide in guides.values():
        for step in guide.steps:
            for raw, _ in step['lines']:
                line, text, _, _ = split_line(raw)
                m = re.match(r'\.(accept|turnin)\s+(\d+)', line)
                if m and text:
                    title = re.sub(r'^(Accept|Turn [Ii]n)\s+', '', clean(text))
                    titles.setdefault(int(m.group(2)), title)
    return titles


# ---------------------------------------------------------------------------
# Routes: which RXP guides make up each Moteve route
# ---------------------------------------------------------------------------
class Chain:
    """Guides that follow each other by #next. cond limits the chain to some races/classes (RXP syntax);
    join=True marks a chain that does not continue an earlier one (a parallel race start, or the
    hand-picked RXP Mage guides after the race start)."""

    def __init__(self, guides, cond='', join=False):
        self.guides, self.cond, self.join = tuple(guides), cond, join


H_TAIL = ('12-17 The Barrens', '17-22 Stonetalon/Barrens/Ashenvale')
A_TAIL = ('14-16 Darkshore', '16-19 Darkshore')
A_END = (Chain(('19-20 Redridge', '20-21 Darkshore/Ashenvale'), '!Hunter'),
         Chain(('19-21 Darkshore/Ashenvale',), 'Hunter'))
# Forever lets other races be Mages: Horde Mages start in their race's zone, Alliance Mages
# without an RXP Mage start (Dwarf, Night Elf) stay on their race route.
ROUTES = (
    dict(id='tauren_rxp', name='Tauren 1–22 (RestedXP)', faction='Horde', races=('TAUREN',), base='tauren', seam=22,
         chains=(Chain(('1-6 Mulgore', '6-12 Mulgore') + H_TAIL),)),
    dict(id='orctroll_rxp', name='Orc / Troll 1–22 (RestedXP)', faction='Horde', races=('ORC', 'TROLL'),
         base='orctroll', seam=22,
         chains=(Chain(('1-6 Durotar', '6-10 Durotar', '10-12 Durotar')),
                 Chain(('10-12 Tirisfal (Orc/Troll)', '12-14 Silverpine Forest'), '!Hunter !Shaman'),
                 Chain(H_TAIL))),
    dict(id='undead_rxp', name='Undead 1–22 (RestedXP)', faction='Horde', races=('UNDEAD', 'SCOURGE'), base='undead',
         seam=22,
         chains=(Chain(('1-6 Tirisfal Glades', '6-12 Tirisfal Glades', '12-14 Silverpine Forest') + H_TAIL),)),
    dict(id='human_rxp', name='Human 1–20 (RestedXP)', faction='Alliance', races=('HUMAN',), base='human', seam=20,
         chains=(Chain(('1-6 Northshire', '6-11 Elwynn Forest', '11-13 Loch Modan')),
                 Chain(('13-15 Westfall',), '!Hunter'),
                 Chain(A_TAIL)) + A_END),
    dict(id='dwarfgnome_rxp', name='Dwarf / Gnome 1–20 (RestedXP)', faction='Alliance', races=('DWARF', 'GNOME'),
         base='dwarfgnome', seam=20,
         chains=(Chain(('1-5 Coldridge Valley', '5-11 Dun Morogh')),
                 Chain(('11-12 Elwynn (Dwarf/Gnome)', '12-14 Loch Modan (Dwarf/Gnome)', '13-15 Westfall'),
                       '!Hunter'),
                 Chain(('11-13 Loch Modan (Hunter)',), 'Hunter'),
                 Chain(A_TAIL)) + A_END),
    dict(id='nightelf_rxp', name='Night Elf 1–20 (RestedXP)', faction='Alliance', races=('NIGHTELF',),
         base='nightelf', seam=20,
         chains=(Chain(('1-6 Shadowglen', '6-11 Teldrassil') + A_TAIL),) + A_END),
    dict(id='mage_h_rxp', name='Horde Mage 1–21 (RestedXP)', faction='Horde', classes=('MAGE',),
         races=('ORC', 'UNDEAD', 'SCOURGE', 'TAUREN', 'TROLL'), base='orctroll', seam=21,
         chains=(Chain(('1-6 Mulgore', '6-12 Mulgore'), 'Tauren'),
                 Chain(('1-6 Durotar', '6-10 Durotar', '10-12 Durotar'), 'Orc/Troll', join=True),
                 Chain(('1-6 Tirisfal Glades', '6-12 Tirisfal Glades'), 'Undead', join=True),
                 Chain(('12-17 The Barrens AoE', '17-21 Stonetalon/Barrens AoE'), join=True))),
    dict(id='mage_a_rxp', name='Alliance Mage 1–21 (RestedXP)', faction='Alliance', classes=('MAGE',),
         races=('HUMAN', 'GNOME'), base='human', seam=21,
         chains=(Chain(('1-10 Elwynn Forest Mage AoE',)),
                 Chain(('1-10 Dun Morogh Mage AoE',), join=True),
                 Chain(('10-12 Loch Modan Mage AoE', '12-18 Darkshore Mage AoE', '18-21 Redridge Mage AoE')))),
    dict(id='mage_aoe_a_rxp', name='Alliance AoE Mage 1–22 (RestedXP ADV)', faction='Alliance', classes=('MAGE',),
         races=('HUMAN', 'GNOME'), base='human', seam=22,
         chains=(Chain(('1-10 ADV Elwynn Forest Human Mage AoE', '10-11 ADV Dun Morogh Human Mage AoE')),
                 Chain(('1-10 ADV Dun Morogh Gnome Mage AoE',), join=True),
                 Chain(('10-12 ADV Darkshore 1 Mage AoE', '12-14 ADV Loch Modan Mage AoE',
                        '14-16 ADV Darkshore 2 Mage AoE', '16-18 ADV Westfall Mage AoE',
                        '18-20 ADV Darkshore 3 Mage AoE', '20-22 ADV Redridge 1 Mage AoE')))),
)


def check_chains(route, guides):
    """Every guide must exist and follow the guide before it by the RXP #next chain."""
    seen_ends = []
    for chain in route['chains']:
        for name in chain.guides:
            if name not in guides:
                raise RXPError(f'{route["id"]}: no guide named {name!r}')
        for a, b in zip(chain.guides, chain.guides[1:]):
            if b not in guides[a].nexts:
                raise RXPError(f'{route["id"]}: {b!r} is not a #next of {a!r}')
        first = chain.guides[0]
        if seen_ends and not chain.join and not any(first in guides[end].nexts for end in seen_ends):
            raise RXPError(f'{route["id"]}: {first!r} does not follow an earlier guide')
        seen_ends.append(chain.guides[-1])


# ---------------------------------------------------------------------------
# Steps
# ---------------------------------------------------------------------------
def default_note(cmd, args, titles):
    arg = args.strip()
    if cmd == 'hs':
        return 'Használd a Hearthstone-t'
    if cmd == 'home':
        return 'Állítsd be a Hearthstone-t' + (f': {arg}' if arg else '')
    if cmd == 'fly':
        return f'Repülj ide: {arg}' if arg else 'Repülj tovább'
    if cmd in ('train', 'trainer'):
        return 'Tanulj a trainernél'
    if cmd == 'vendor':
        return 'Árus: add el a felesleget'
    if cmd == 'collect':
        return 'Szerezd meg a szükséges tárgyat'
    if cmd == 'use':
        return 'Használd a tárgyat'
    if cmd == 'equip':
        return 'Vedd fel a tárgyat'
    if cmd == 'zone':
        return f'Utazz ide: {arg}' if arg else 'Utazz tovább'
    if cmd == 'subzone':
        return 'Utazz tovább'
    if cmd == 'deathskip':
        return 'Halj meg, és támadj fel a Spirit Healernél'
    q = int(arg.split(',')[0]) if arg.split(',')[0].isdigit() else None
    return 'Add fel a questet' + (f': {titles.get(q, q)}' if q else '')


def race_class_groups(pairs, races, classes):
    """Split a set of (race, class) pairs into (rr, cls) bitmasks; 0 / None when it covers the route."""
    by_race = {}
    for r in RACES:
        cs = frozenset(c for c in classes if (r, c) in pairs)
        if r in races and cs:
            by_race.setdefault(cs, []).append(r)
    out = []
    for cs, rs in by_race.items():
        rr = 0 if set(rs) == set(races) else sum(RACEBIT[r] for r in rs)
        cls = None if cs == frozenset(classes) else sum(CLASSBIT[c] for c in CLASSES if c in cs)
        out.append((rr, cls))
    return out


def convert_step(step, scope, domain, titles, el):
    """One RXP step -> Moteve steps (dicts). domain: the (race, class) pairs of the route; scope: the
    pairs this guide is for. Pairs that do not span the domain become rr / cls bits."""
    where = step['where']
    _, _, cond, _ = split_line(step['head'])
    shown = scope & condition(cond, where)
    actions, notes, texts, gotos, pre, ex, mobs = [], [], [], [], [], [], []
    loop, npc, comment_of = False, None, {}
    for raw, lwhere in step['lines']:
        if raw.startswith('#'):
            body, _, dcond, _ = split_line(raw)
            name, _, arg = body[1:].partition(' ')
            loop = loop or name == 'loop'
            if not directive_shown(name, arg, lwhere):
                shown = shown - condition(dcond, lwhere)
            continue
        if raw.startswith('*'):
            continue
        line, text, lcond, comment = split_line(raw)
        lset = condition(lcond, lwhere)
        if not line.startswith('.'):
            text = clean((line[1:] if line.startswith('+') else line) + ' ' + text)
            if text:
                texts.append((text, lset))
            continue
        cmd, _, args = line[1:].partition(' ')
        args = args.strip()
        if cmd not in KNOWN_COMMANDS:
            raise RXPError(f'{lwhere}: unknown command .{cmd}')
        if cmd in DROP_COMMANDS:
            return []
        if cmd == 'goto':
            gotos.append((parse_goto(args, lwhere), lset))
            if text:
                texts.append((clean(text), lset))
        elif cmd == 'target':
            npc = npc or clean(args)
        elif cmd in MOB_COMMANDS:
            names = args.split(';') if cmd == 'unitscan' else [args]
            mobs += [(name, lset) for name in (clean(n.strip().lstrip('+')) for n in names) if name]
        elif cmd in QUEST_CONDITIONS:
            q = int(args.split(',')[0])
            if cmd == 'isQuestTurnedIn':
                pre.append(('*', q))
            elif cmd in ('isOnQuest', 'isQuestComplete'):
                pre.append((q, q))
            elif cmd in ('isQuestAvailable', 'isNotOnQuest'):
                ex.append(q)
        elif cmd == 'xp' and (args[:1] in ('<', '>') or args.split()[0].endswith(',1')):
            continue   # a level condition or skip-at-level ('.xp 10,1'), not a level to reach
        elif cmd in QUEST_ACTIONS:
            actions.append((cmd, args, clean(text), lset, comment))
        elif cmd in NOTE_COMMANDS:
            notes.append((cmd, args, clean(text), lset))
    if not shown:
        return []

    def place(s, pairs):
        usable = [g for g, gset in gotos if gset & pairs]
        if usable:
            m, x, y = usable[0] if loop else usable[-1]
            s.update(m=m, x=round(x, 2), y=round(y, 2))

    def text_for(pairs):
        return ' '.join(t for t, tset in texts if tset & pairs)

    out = []

    def emit(s, pairs):
        for rr, cls in race_class_groups(pairs, scope_races(domain), scope_classes(domain)):
            copy = dict(s)
            if cls is not None:
                copy['cls'] = cls
            if rr:
                copy['rr'] = rr
            copy['el'] = el
            out.append(copy)

    for cmd, args, text, lset, comment in actions:
        pairs = shown & lset
        if not pairs:
            continue
        nums = args.split(',')
        if cmd == 'xp':
            lv, xp = parse_xp(args, where)
            s = {'k': 'grind', 't': text or text_for(pairs) or grind_text(lv, xp), 'lv': lv, 'xp': xp}
            place(s, pairs)
        elif cmd == 'fp':
            name = args or re.sub(r'^Get the (.*?) flight path.*$', r'\1', text)
            s = {'k': 'fp', 't': f'Repülési pont: {name}'}
            place(s, pairs)
            s['npc'] = npc or name
        else:
            q = int(nums[0])
            k = {'accept': 'a', 'turnin': 't', 'complete': 'c'}[cmd]
            s = {'k': k, 'q': q}
            if k == 'c':
                s['oi'] = int(nums[1]) if len(nums) > 1 and nums[1].strip().isdigit() else None
            place(s, pairs)
            s['t'] = titles.get(q, f'Quest {q}')
            if k == 'c':
                s['obj'] = text_for(pairs) or clean(comment)
                s['mob'] = list(dict.fromkeys(name for name, mset in mobs if mset & pairs))
            elif npc:
                s['npc'] = npc
            s['pre'] = sorted({p for target, p in pre if target in ('*', q)})
            s['ex'] = sorted({e for e in ex if e != q})
        emit(s, pairs)
    if not actions and (notes or texts):
        pairs = shown
        if notes or any(tset != ALL for _, tset in texts):
            pairs = shown & frozenset().union(*[n[3] for n in notes], *[tset for _, tset in texts])
        if pairs:
            note_text = next((t for _, _, t, nset in notes if t and nset & pairs), '') or text_for(pairs)
            if not note_text:
                cmd, args, _, _ = notes[0]
                note_text = default_note(cmd, args, titles)
            s = {'k': 'note', 't': note_text}
            place(s, pairs)
            if npc:
                s['npc'] = npc
            emit(s, pairs)
    return out


def parse_xp(args, where):
    """'.xp N' -> (N, None); 'N+X' -> X xp into level N; 'N-X' -> X xp short of level N, i.e. level N-1
    with xp=-X (counted back from UnitXPMax); 'N.f' -> fraction 0.f of level N's bar."""
    m = re.fullmatch(r'(\d+)(?:([+-])(\d+)|(\.\d+))?', args.split()[0])
    if not m:
        raise RXPError(f'{where}: bad .xp {args!r}')
    lv = int(m.group(1))
    if m.group(2) == '+':
        return lv, int(m.group(3))
    if m.group(2) == '-':
        return lv - 1, -int(m.group(3))
    if m.group(4):
        return lv, float(m.group(4))
    return lv, None


def grind_text(lv, xp):
    if xp is None:
        return f'Ölj mobokat, amíg eléred a {lv}. szintet'
    if xp < 0:
        return f'Ölj mobokat, amíg {-xp} XP hiányzik a {lv + 1}. szintig'
    if xp < 1:
        return f'Ölj mobokat, amíg eléred a {lv}. szint {round(xp * 100)}%-át'
    return f'Ölj mobokat, amíg eléred a {lv}. szinten a {xp} XP-t'


def scope_races(scope):
    return [r for r in RACES if any(p[0] == r for p in scope)]


def scope_classes(scope):
    return [c for c in CLASSES if any(p[1] == c for p in scope)]


def build_route(route, guides, titles):
    check_chains(route, guides)
    domain = frozenset((r, c) for r, c in ALL if r in FACTION_RACES[route['faction']]
                       and c in route.get('classes', CLASSES))
    steps = []
    for chain in route['chains']:
        chain_set = condition(chain.cond, route['id'])
        for name in chain.guides:
            guide = guides[name]
            scope = domain & chain_set & condition(guide.cond, guide.where)
            el = guide.level
            zone = {'k': 'zone', 't': f'{name} (RestedXP)'}
            if scope_classes(scope) != scope_classes(domain):
                zone['cls'] = sum(CLASSBIT[c] for c in scope_classes(scope))
            if scope_races(scope) != scope_races(domain):
                zone['rr'] = sum(RACEBIT[r] for r in scope_races(scope))
            zone['el'] = el
            steps.append(zone)
            add_steps(steps, guide, scope, domain, guides, titles, el)
    return steps


def add_steps(steps, guide, scope, domain, guides, titles, el):
    """Append a guide's steps; a step with '#include <guide>' brings in that guide's steps."""
    for step in guide.steps:
        include = [raw for raw, _ in step['lines'] if raw.startswith('#include ')]
        if include:
            name = split_line(include[0][len('#include '):])[0].strip()
            if name not in guides:
                raise RXPError(f'{step["where"]}: no guide named {name!r} to #include')
            inner = guides[name]
            inner_scope = (scope & condition(split_line(step['head'])[2], step['where'])
                           & condition(inner.cond, inner.where))
            el = add_steps(steps, inner, inner_scope, domain, guides, titles, el)
            continue
        for s in convert_step(step, scope, domain, titles, el):
            steps.append(s)
            if s['k'] == 'grind':
                el = max(el, s['lv'])
    return el


# ---------------------------------------------------------------------------
# Lua output
# ---------------------------------------------------------------------------
FIELDS = ('k', 'q', 'oi', 'm', 'x', 'y', 't', 'npc', 'mob', 'obj', 'lv', 'xp', 'cls', 'rr', 'pre', 'ex', 'el')


def lua_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', ' ') + '"'


def lua_value(v):
    if isinstance(v, str):
        return lua_str(v)
    if isinstance(v, float):
        return f'{v:.2f}'.rstrip('0').rstrip('.')
    if isinstance(v, (list, tuple)):
        return '{' + ','.join(lua_value(x) for x in v) + '}'
    return str(v)


def lua_step(s):
    parts = []
    for f in FIELDS:
        v = s.get(f)
        if v is None or v == '' or v == []:
            continue
        parts.append(f'{f}={lua_value(v)}')
    return '{' + ', '.join(parts) + '}'


HEADER = f'''-- Moteve Guide - RestedXP WoW Forever routes: Alliance 1-20, Horde 1-22, and the Mage routes.
-- Source: RestedXP/RXPGuides (https://github.com/RestedXP/RXPGuides), Guides/forever at commit
-- {RXP_SHA}. Licensed under CC BY-NC-SA 4.0, see RXP-LICENSE.
-- Modified: converted to Moteve Guide steps by tools/import_rxp.py (softcore branch only, WoW text
-- codes removed), and continued above 20/22 with the existing Moteve routes.
-- Do not edit by hand; rerun python3 tools/import_rxp.py.
local _, ns = ...
local routes = {{}}
'''

FOOTER = '''
-- Above the seam level each route continues with its existing Moteve route, from the first zone
-- that starts at the seam (or the last zone before it), leaving out the quests the RestedXP
-- part already turns in. The new routes go to the front, so GuideForRace picks them first.
local function SeamIndex(steps, level)
    local last
    for i, s in ipairs(steps) do
        if s.k == "zone" then
            if (s.el or 1) >= level then return i end
            last = i
        end
    end
    return last
end
local byId = {}
for _, g in ipairs(ns.GUIDES) do byId[g.id] = g end
for n = #routes, 1, -1 do
    local r = routes[n]
    local base = byId[r.base]
    local from = base and SeamIndex(base.steps, r.seam)
    if from then
        local done = {}
        for _, s in ipairs(r.steps) do if s.k == "t" and s.q then done[s.q] = true end end
        for i = from, #base.steps do
            local s = base.steps[i]
            if not (s.q and (s.k == "a" or s.k == "c" or s.k == "t") and done[s.q]) then r.steps[#r.steps + 1] = s end
        end
    end
    table.insert(ns.GUIDES, 1, r)
end
'''


def lua_set(names):
    return '{' + ','.join(f'{n}=true' for n in names) + '}'


def render(routes):
    out = [HEADER]
    for route, steps in routes:
        head = (f'{{ id={lua_str(route["id"])}, name={lua_str(route["name"])}, races={lua_set(route["races"])}, '
                f'faction={lua_str(route["faction"])}, ')
        if route.get('classes'):
            head += f'classes={lua_set(route["classes"])}, '
        head += f'base={lua_str(route["base"])}, seam={route["seam"]}, steps = {{'
        # one function per route keeps each under Lua's per-function constant limit
        out.append(f'routes[#routes + 1] = (function() return {head}\n')
        out.extend(f'    {lua_step(s)},\n' for s in steps)
        out.append('} } end)()\n')
    out.append(FOOTER)
    return ''.join(out)


def generate(src_dir=SRC_DIR):
    guides = load_guides(src_dir)
    titles = quest_titles(guides)
    return render([(route, build_route(route, guides, titles)) for route in ROUTES])


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--out', type=Path, default=OUT)
    args = parser.parse_args(argv)
    try:
        text = generate()
    except RXPError as e:
        print(f'import_rxp: {e}', file=sys.stderr)
        return 1
    args.out.write_text(text, encoding='utf-8', newline='\n')
    print(f'PASS: {args.out} from RestedXP/RXPGuides {RXP_SHA[:10]}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
