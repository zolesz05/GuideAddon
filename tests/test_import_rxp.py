"""Tests for tools/import_rxp.py, the generated MoteveGuide/RXPRoutes.lua and the addon package.

Run from the repo root: python3 -m unittest discover -s tests
"""
from pathlib import Path
import contextlib
import hashlib
import io
import re
import shutil
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import import_rxp as rxp  # noqa: E402

GUIDE = '1-6 Test'


def convert(body, header='<< Horde', faction='Horde', classes=None, titles=None):
    """Steps of a one-guide route made of an RXP step body (without the zone step)."""
    text = f'RXPGuides.RegisterGuide([[\n#name {GUIDE}\n{header}\nstep\n{body}\n]])'
    guide = rxp.parse_guide(rxp.GUIDE_RE.findall(text)[0], 'test')
    route = dict(id='test', name='Test', faction=faction, races=('TAUREN',), base='tauren', seam=22,
                 chains=(rxp.Chain((GUIDE,)),))
    if classes:
        route['classes'] = classes
    guides = {GUIDE: guide}
    steps = rxp.build_route(route, guides, titles or rxp.quest_titles(guides))
    assert steps[0]['k'] == 'zone'
    return steps[1:]


GOTO = '.goto 1412/1,-259.85,-2914.28'   # Mulgore 44.92, 77.12


class SourceTest(unittest.TestCase):
    def test_sha_is_one_constant(self):
        source = (ROOT / 'tools' / 'import_rxp.py').read_text(encoding='utf-8')
        self.assertRegex(rxp.RXP_SHA, r'^[0-9a-f]{40}$')
        self.assertEqual(source.count(rxp.RXP_SHA), 1)
        self.assertTrue((ROOT / 'tools' / 'rxp_src' / rxp.RXP_SHA / 'LICENSE').is_file())

    def test_allowlist_is_the_twelve_free_forever_files(self):
        self.assertEqual(set(rxp.ALLOWED_FILES), {
            'Horde-1-12_Mulgore.lua', 'Horde-01-12_Durotar.lua', 'Horde-01-14_Undead.lua', 'Horde-12-22_Barrens.lua',
            'Alliance-1-13_Human.lua', 'Alliance-1-14_DwarfGnome.lua', 'Alliance-1-10_NightElf.lua',
            'Alliance-11-20.lua', 'Horde-Mage-12-21.lua', 'Alliance-Mage-1-12.lua', 'Alliance-Mage-12-21.lua',
            'Alliance-ADV-AoE-Mage-1-22.lua'})
        self.assertEqual(len(rxp.ALLOWED_FILES), 12)
        self.assertEqual(sorted(p.name for p in rxp.SRC_DIR.glob('*.lua')), sorted(rxp.ALLOWED_FILES))

    def test_file_outside_the_allowlist_stops(self):
        with self.assertRaisesRegex(rxp.RXPError, 'allowlist'):
            rxp.read_source('Horde-22-30_Hillsbrad.lua')

    def test_extra_file_in_the_source_folder_stops(self):
        with tempfile.TemporaryDirectory() as tmp:
            for name in rxp.ALLOWED_FILES:
                shutil.copy(rxp.SRC_DIR / name, tmp)
            (Path(tmp) / 'Horde-22-30_Hillsbrad.lua').write_text('', encoding='utf-8')
            with self.assertRaisesRegex(rxp.RXPError, 'Horde-22-30_Hillsbrad.lua'):
                rxp.load_guides(tmp)


class OutputTest(unittest.TestCase):
    def test_two_runs_give_the_committed_file(self):
        with tempfile.TemporaryDirectory() as tmp:
            a, b = Path(tmp) / 'a.lua', Path(tmp) / 'b.lua'
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(rxp.main(['--out', str(a)]), 0)
                self.assertEqual(rxp.main(['--out', str(b)]), 0)
            self.assertEqual(a.read_bytes(), b.read_bytes())
            self.assertEqual(a.read_bytes(), (ROOT / 'MoteveGuide' / 'RXPRoutes.lua').read_bytes())

    def test_header_names_source_sha_license_and_changes(self):
        head = '\n'.join((ROOT / 'MoteveGuide' / 'RXPRoutes.lua').read_text(encoding='utf-8').splitlines()[:8])
        self.assertIn('RestedXP/RXPGuides', head)
        self.assertIn(rxp.RXP_SHA, head)
        self.assertIn('CC BY-NC-SA 4.0', head)
        self.assertIn('Modified', head)

    def test_license_is_the_full_rxp_license(self):
        text = (ROOT / 'MoteveGuide' / 'RXP-LICENSE').read_text(encoding='utf-8')
        self.assertEqual(text, (rxp.SRC_DIR / 'LICENSE').read_text(encoding='utf-8'))
        self.assertIn('Attribution-NonCommercial-ShareAlike 4.0 International Public License', text)
        self.assertIn('Section 8 – Interpretation.', text)

    def test_tauren_route_has_no_mulgore_flight_path(self):
        guides = rxp.load_guides()
        route = next(r for r in rxp.ROUTES if r['id'] == 'tauren_rxp')
        steps = rxp.build_route(route, guides, rxp.quest_titles(guides))
        self.assertTrue(any(s['k'] == 'fp' for s in steps))
        self.assertEqual([s for s in steps if s['k'] == 'fp' and s.get('m') == 1412], [])

    def test_routes_follow_the_next_chain(self):
        guides = rxp.load_guides()
        for route in rxp.ROUTES:
            rxp.check_chains(route, guides)
        bad = dict(rxp.ROUTES[0], chains=(rxp.Chain(('1-6 Mulgore', '12-17 The Barrens')),))
        with self.assertRaisesRegex(rxp.RXPError, 'not a #next'):
            rxp.check_chains(bad, guides)


# sha256 of the files at main 49f25ff
OLD_ROUTES = {
    'Guides.lua': '4941bbb06996de1a9cda0d66399c960b7f0a39b650c60ad63f7120951b1089da',
    'ZoneGuides.lua': '950e4a0a64d9fc9aed1757f69ae1ecd07c42eba05457a85db351c53f33ff30e3',
}


class OldRoutesTest(unittest.TestCase):
    def test_old_routes_are_unchanged(self):
        for name, digest in OLD_ROUTES.items():
            data = (ROOT / 'MoteveGuide' / name).read_bytes()
            self.assertEqual(hashlib.sha256(data).hexdigest(), digest, name)


class PackageTest(unittest.TestCase):
    def test_toc_loads_rxp_routes_after_zone_guides(self):
        toc = (ROOT / 'MoteveGuide' / 'MoteveGuide.toc').read_text(encoding='utf-8')
        files = [l.strip() for l in toc.splitlines() if l.strip() and not l.startswith('#')]
        self.assertEqual(files.index('RXPRoutes.lua'), files.index('ZoneGuides.lua') + 1)
        self.assertRegex(toc, r'(?m)^## Version: 0\.8\.0$')

    def test_zip_has_the_routes_and_the_license(self):
        with zipfile.ZipFile(ROOT / 'downloads' / 'MoteveGuide.zip') as z:
            names = z.namelist()
            self.assertIn('MoteveGuide/RXPRoutes.lua', names)
            self.assertIn('MoteveGuide/RXP-LICENSE', names)
            self.assertEqual(z.read('MoteveGuide/RXPRoutes.lua'), (ROOT / 'MoteveGuide' / 'RXPRoutes.lua').read_bytes())


class CommandTest(unittest.TestCase):
    def one(self, body, **kw):
        steps = convert(body, **kw)
        self.assertEqual(len(steps), 1, steps)
        return steps[0]

    def test_accept(self):
        s = self.one(f'{GOTO}\n.accept 747 >>Accept The Hunt Begins\n.target Grull Hawkwind')
        self.assertEqual((s['k'], s['q'], s['t'], s['npc'], s['m']), ('a', 747, 'The Hunt Begins', 'Grull Hawkwind', 1412))
        self.assertEqual((round(s['x'], 2), round(s['y'], 2)), (44.92, 77.12))

    def test_turnin(self):
        s = self.one(f'{GOTO}\n.turnin 747,1 >>Turn in The Hunt Begins')
        self.assertEqual((s['k'], s['q'], s['t']), ('t', 747, 'The Hunt Begins'))

    def test_complete_keeps_the_objective_index(self):
        steps = convert('.complete 747,1 --Plainstrider Meat (7)\n.complete 747,2 --Plainstrider Feather (7)',
                        titles={747: 'The Hunt Begins'})
        self.assertEqual([(s['k'], s['q'], s['oi']) for s in steps], [('c', 747, 1), ('c', 747, 2)])
        self.assertEqual(steps[0]['t'], 'The Hunt Begins')
        self.assertEqual(steps[0]['obj'], 'Plainstrider Meat (7)')

    def test_fp(self):
        s = self.one(f'{GOTO}\n.fp Camp Taurajo >> Get the Camp Taurajo flight path\n.target Omusa Thunderhorn')
        self.assertEqual((s['k'], s['t'], s['npc']), ('fp', 'Repülési pont: Camp Taurajo', 'Omusa Thunderhorn'))

    def test_xp_is_a_grind_to_the_level(self):
        s = self.one('.xp 6 >> Grind to level 6')
        self.assertEqual((s['k'], s['lv'], s['t']), ('grind', 6, 'Grind to level 6'))
        self.assertEqual(self.one('.xp 3+1150 >> Grind')['lv'], 3)

    def test_xp_below_is_a_condition_not_a_grind(self):
        self.assertEqual(convert('.xp <10,1\n.accept 1 >>Accept A')[0]['k'], 'a')

    def test_goto_with_text_is_a_note(self):
        s = self.one(f'{GOTO} >> Travel to Bloodhoof Village')
        self.assertEqual((s['k'], s['t'], s['m']), ('note', 'Travel to Bloodhoof Village', 1412))
        s = self.one(f'{GOTO}\n>>Run up the hill')
        self.assertEqual((s['k'], s['t']), ('note', 'Run up the hill'))

    def test_goto_without_text_is_left_out(self):
        self.assertEqual(convert(GOTO), [])

    def test_manual_commands_are_notes(self):
        for body in ('.hs >> Hearth to Thunder Bluff', '.home >> Set your Hearthstone to Bloodhoof',
                     '.fly Crossroads >> Fly to The Crossroads', '.train 6673 >>Train Battle Shout',
                     '.vendor >> Vendor Trash', '.collect 2516,1000,750,1 --Light Shot (1000)', '.use 2132',
                     '.equip 16,6256 >> Equip the Fishing Pole'):
            with self.subTest(body=body):
                s = self.one(f'{GOTO}\n{body}\n.target Someone')
                self.assertEqual((s['k'], s['m'], s['npc']), ('note', 1412, 'Someone'))
                self.assertTrue(s['t'])
        self.assertEqual(self.one('.hs >> Hearth to Thunder Bluff')['t'], 'Hearth to Thunder Bluff')
        self.assertEqual(self.one('.use 2132')['t'], 'Használd a tárgyat')

    def test_note_is_not_added_to_quest_steps(self):
        steps = convert('.turnin 1 >>Turn in A\n.vendor >> Vendor Trash')
        self.assertEqual([s['k'] for s in steps], ['t'])

    def test_class_condition_sets_cls_bits(self):
        s = self.one('.accept 1 >>Accept A << Warrior/Shaman')
        self.assertEqual(s['cls'], 1 + 64)
        self.assertNotIn('rr', s)
        steps = convert('.accept 1 >>Accept A << !Druid')
        self.assertEqual(steps[0]['cls'], sum(rxp.CLASSBIT.values()) - 1024)

    def test_step_condition_applies_to_its_lines(self):
        text = 'RXPGuides.RegisterGuide([[\n#name 1-6 Test\n<< Horde\nstep << Mage\n.accept 1 >>Accept A\n]])'
        guide = rxp.parse_guide(rxp.GUIDE_RE.findall(text)[0], 'test')
        route = dict(id='t', name='t', faction='Horde', races=(), base='x', seam=1, chains=(rxp.Chain(('1-6 Test',)),))
        steps = rxp.build_route(route, {'1-6 Test': guide}, {})
        self.assertEqual(steps[1]['cls'], 128)

    def test_race_condition_sets_rr_bits(self):
        s = self.one('.accept 1 >>Accept A << Tauren')
        self.assertEqual(s['rr'], 32)
        self.assertNotIn('cls', s)

    def test_negated_race_condition_sets_the_other_races(self):
        s = self.one('.accept 1 >>Accept A << !Tauren')
        self.assertEqual(s['rr'], 2 + 16 + 128)   # the other Horde races

    def test_race_and_class_together(self):
        steps = convert('.accept 1 >>Accept A << Orc Hunter/Troll Warrior')
        self.assertEqual(sorted((s['rr'], s['cls']) for s in steps), [(2, 4), (128, 1)])

    def test_condition_for_the_other_faction_drops_the_step(self):
        self.assertEqual(convert('.accept 1 >>Accept A << Human'), [])

    def test_mage_route_keeps_mage_steps_only(self):
        steps = convert('.accept 1 >>Accept A << Warrior\n.accept 2 >>Accept B << Mage\n.accept 3 >>Accept C',
                        classes=('MAGE',))
        self.assertEqual([(s['q'], s.get('cls')) for s in steps], [(2, None), (3, None)])

    def test_softcore_is_kept_and_hardcore_dropped(self):
        steps = convert('#softcore\n.accept 1 >>Accept A\nstep\n#hardcore\n.accept 2 >>Accept B')
        self.assertEqual([s['q'] for s in steps], [1])

    def test_hardcore_for_some_classes_drops_it_for_them(self):
        s = self.one('#hardcore << Warrior\n.accept 1 >>Accept A')
        self.assertEqual(s['cls'], sum(rxp.CLASSBIT.values()) - 1)

    def test_completewith_steps_are_left_out(self):
        self.assertEqual(convert('#completewith next\n.complete 747,1'), [])

    def test_dungeon_steps_are_left_out(self):
        self.assertEqual(convert('.dungeon RFC\n.accept 1 >>Accept A'), [])

    def test_quest_conditions(self):
        s = self.one('.turnin 5 >>Turn in A\n.isQuestComplete 5\n.isQuestTurnedIn 4\n.isQuestAvailable 6')
        self.assertEqual((s['pre'], s['ex']), ([4, 5], [6]))

    def test_zone_name_goto(self):
        s = self.one('.goto Loch Modan,35.5,46.9\n>>Go')
        self.assertEqual((s['m'], s['x'], s['y']), (1432, 35.5, 46.9))
        s = self.one('.goto 1411,44.9,68.0\n>>Go')
        self.assertEqual((s['m'], s['x'], s['y']), (1411, 44.9, 68.0))

    def test_unknown_zone_stops(self):
        with self.assertRaisesRegex(rxp.RXPError, "unknown zone 'Narnia'"):
            convert('.goto Narnia,10,10\n>>Go')

    def test_unknown_command_stops(self):
        with self.assertRaisesRegex(rxp.RXPError, 'unknown command .teleport'):
            convert('.teleport 1')

    def test_unknown_condition_stops(self):
        with self.assertRaisesRegex(rxp.RXPError, 'unknown condition'):
            convert('.accept 1 >>Accept A << Pandaren')

    def test_text_is_cleaned_of_wow_codes(self):
        s = self.one('>>|Tinterface/worldmap/chatbubble_64grey.blp:20|tTalk to |cRXP_FRIENDLY_Grull|r')
        self.assertEqual(s['t'], 'Talk to Grull')

    def test_lua_output_escapes_strings(self):
        self.assertEqual(rxp.lua_step({'k': 'note', 't': 'say "hi" \\', 'x': 44.0, 'el': 1}),
                         '{k="note", x=44, t="say \\"hi\\" \\\\", el=1}')


if __name__ == '__main__':
    unittest.main()
