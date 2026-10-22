# Moteve Guide

**Moteve Guide** egy World of Warcraft addon a WoW Forever klienshez. Horde és Alliance karaktereket segít a fejlődésben 1–30-as szintig: sorban mutatja a feladatokat, követi a küldetéscélokat, és nyíllal vezet az aktuális célponthoz.

A magyar kezelőfelülethez állítható méretű ablak, öt választható kinézet és külön beállítható irányjelző tartozik.

**Aktuális verzió: 0.8.0**

[Az addon letöltése (ZIP)](downloads/MoteveGuide.zip?raw=true)

A letöltési link mindig a legfrissebb telepíthető csomagra mutat. A `downloads` mappában csak az aktuális `MoteveGuide.zip` szerepel; a régebbi kiadások külön ZIP-ként nem maradnak ott.

## Telepítés

1. Töltsd le és csomagold ki a fenti ZIP-et.
2. Másold a `MoteveGuide` mappát a játék `Interface/AddOns/` könyvtárába. A jelenlegi célkönyvtár: `_classic_beta_/Interface/AddOns/MoteveGuide/`.
3. Az addonlistán engedélyezd a Moteve Guide-ot, majd lépj be a karaktereddel.
4. A `/mg` paranccsal jelenítheted meg az ablakot, a `/mg opciok` paranccsal nyithatod meg a beállításokat.

A ZIP-ben lévő mappanevet tartsd meg: a `MoteveGuide.toc` közvetlenül a `MoteveGuide` mappában legyen.

```text
Interface/
└── AddOns/
    └── MoteveGuide/
        ├── MoteveGuide.toc
        ├── Guide.lua
        ├── Fonts/
        └── Textures/
```

Frissítéskor cseréld le az addon mappáját az új csomagra. Új fájlok telepítése után indítsd újra a klienst; a már betöltött fájlok frissítéséhez `/reload` is használható. A `WTF` könyvtárat tartsd meg, mert ott tárolja a játék a beállításokat és a haladást.

## Funkciók

- Horde és Alliance útvonalak, zónaválasztóval, 1–30-as szintig.
- Aktuális és következő feladatok, küldetéscélok előrehaladásával.
- Irányjelző nyíl, távolság és térképes célpont.
- Automatikus léptetés: a már teljesített lépéseket átugorja a következő teendőig.
- Korábbi lépések visszanézése a bal nyíllal és kétirányú görgetéssel.
- Öt függetlenül választható ablak- és nyílkinézet: Eredeti, Minimal, Classic Light, Glass, Moteve. Új beállításoknál a Moteve az alapértelmezett.
- Átméretezhető ablak, XP/óra kijelzés, állítható számú következő lépés.
- Automatikus küldetésfelvétel és -leadás, kikapcsolható beállítással.
- Magyar ékezeteket támogató betűtípusok a panelen és a súgóbuborékokban.

## Használat

Az addon első induláskor a karakter fajához illő főútvonalat választja. Másik útvonalat vagy zónaszakaszt a fejlécen jobb kattintással, illetve a beállítópanel útvonalválasztójával választhatsz.

Az aktív sor a jelenlegi teendőt mutatja. Felvétel, célkitűzés teljesítése vagy leadás után az addon automatikusan továbbhalad, és az előre teljesített feladatokat is átugorja. Ha egy küldetés már kész, de még nincs leadva, a leadási lépésnél megáll.

| Kezelés | Működés |
| --- | --- |
| Bal nyíl | Előző lépés visszanézése, akkor is, ha már teljesült |
| Jobb nyíl | Folytatás a következő teendőig; a még befejezetlen aktuális lépést kézzel kihagyja |
| Egérgörgő a listán | Korábbi és későbbi lépések böngészése az aktív célpont átállítása nélkül |
| Bal kattintás egy soron | A kiválasztott lépés megnyitása |
| Jobb kattintás egy soron | A lépés kézi kihagyása |
| Fejléc húzása | Ablak mozgatása |
| Jobb alsó sarok húzása | Ablak átméretezése |

Visszanézés közben a frissítések nem ugranak el a kiválasztott korábbi lépésről. A jobb nyíllal folytathatod a haladást. A visszalépés nem törli a küldetések teljesítését vagy a kézzel kihagyott lépések jelölését.

Az automatikus küldetésfelvétel és -leadás kikapcsolható a beállításokban; **Shift** nyomva tartásával ideiglenesen is felfüggeszthető. Több választható jutalom esetén a jutalmat kézzel kell kiválasztanod.

## Kinézetek és beállítások

A **Beállítások → AddOns → Moteve Guide** panelen az ablak és a nyíl kinézete egymástól függetlenül választható.

| Kinézet | Megjelenés |
| --- | --- |
| Eredeti | Díszes bronzkeret, klasszikus fantasy elemek |
| Minimal | Sötét, letisztult panel, vékony szegély |
| Classic Light | Meleg sötét tónusok, visszafogott bronzkeret és klasszikus címbetűk |
| Glass | Áttetsző szürkéskék háttér és finom keret |
| Moteve | A Moteve Chathez és Damage Meterhez illő, áttetsző sötétkék felület, lila kiemelések és cián nyíl |

Új beállításoknál a **Moteve** az alapértelmezett. A korábban elmentett kinézetválasztás frissítés után is megmarad. A váltás azonnali; mind a 25 ablak–nyíl párosítás használható. A Glass áttetszőséget alkalmaz, háttérelmosást nem. A Moteve stílus a Chat és Damage Meter színeit használja: Marcellus címek, Barlow szövegek, lila aktív jelölő és XP-sáv, cián célkitűzéssávok és mentazöld teljesítések. Minden nyíl karika és kör alakú háttér nélkül jelenik meg. Használatához a másik két addon telepítése nem szükséges.

Ugyanitt kapcsolható az ablak, a nyíl, a térképes céljelölő, az automatikus küldetéskezelés és az XP-sor. A következő feladatok száma 0–8 között, az ablak mérete 55–130% között állítható.

## Útvonalak

A csomag kilenc RestedXP-alapú útvonalat, hat főútvonalat és 32 külön zónaútvonalat tartalmaz, 23 zónával. A választó a karakter frakciójának megfelelő útvonalakat kínálja.

Új karakter alapból a RestedXP ingyenes WoW Forever guide-jának útvonalát kapja (Alliance 1–20, Horde 1–22), Mage a frakciója RestedXP Mage-útvonalát. 20/22 felett a régi főútvonal folytatódik, a már leadott questek nélkül. A meglévő karakterek a mentett útvonalukon maradnak.

| Karakter / főútvonal | Kiválasztás |
| --- | --- |
| Human / Dwarf, Gnome / Night Elf 1–20 (RestedXP) | `/mg guide human_rxp` · `dwarfgnome_rxp` · `nightelf_rxp` |
| Orc, Troll / Tauren / Undead 1–22 (RestedXP) | `/mg guide orctroll_rxp` · `tauren_rxp` · `undead_rxp` |
| Mage (RestedXP) | `/mg guide mage_h_rxp` · `mage_a_rxp` · `mage_aoe_a_rxp` |
| Human | `/mg guide human` |
| Dwarf / Gnome | `/mg guide dwarfgnome` |
| Night Elf | `/mg guide nightelf` |
| Orc / Troll | `/mg guide orctroll` |
| Tauren | `/mg guide tauren` |
| Undead | `/mg guide undead` |

A külön zónák között megtalálhatók a kezdőterületek, például Elwynn Forest, Mulgore és Durotar, valamint Westfall, The Barrens, Ashenvale, Hillsbrad Foothills és Zephras Isle is. A teljes listát és a zónánkénti parancsokat a [zónaleírás](MoteveGuide/ZONES.md) tartalmazza.

## Parancsok

| Parancs | Művelet |
| --- | --- |
| `/mg` | Ablak megjelenítése / elrejtése |
| `/mg opciok` | Beállítások megnyitása |
| `/mg prev` | Előző lépés megtekintése |
| `/mg next` | Következő teendő / aktuális lépés kihagyása |
| `/mg nyil` | Irányjelző be- és kikapcsolása |
| `/mg scale 70` | Ablakméret beállítása százalékban |
| `/mg auto` | Automatikus küldetésfelvétel / -leadás kapcsolása |
| `/mg guide <azonosító>` | Főútvonal vagy zónaútvonal kiválasztása |
| `/mg reset` | A kézi kihagyások és a guide saját repülőpont-jelöléseinek törlése, újrakezdés az aktuális szint alapján |

A `/mg reset` a küldetésnaplót és a játékban már teljesített küldetéseket nem módosítja. A `/mguide` a `/mg` alternatívája.

## Kompatibilitás és ismert korlátok

- A csomag célkliense **WoW Forever**, a TOC-fájl Interface-értéke **16001**. Más WoW-verziókkal való működés nincs igazolva.
- A küldetésadatok a csomag részei; használatához külön Questie telepítése nem szükséges.
- Az útvonalsorrendet adatbázisból generáltuk; a teljes 1–30-as játékmenet még nincs végigellenőrizve.
- A feladatok elérhetősége függhet a fajtól, kaszttól és az előküldetésektől. A hiányzó előfeltétel miatt még nem elérhető folytatást átugorhatja.
- A csomag nem tartalmaz minden kaszt-, dungeon-, szakma- és ismételhető küldetést. Egyes szakaszokhoz grind is tartozik.
- Az utazási és figyelmeztető lépések kézi továbblépést igényelhetnek; a nyíl nem tervez hajó- vagy repülőjárat-útvonalat.

## Hibajelentés

Hibát a repository [Issues oldalán](https://github.com/zolesz05/GuideAddon/issues) jelezhetsz. Add meg az addon és a kliens verzióját, a karakter faját és kasztját, az útvonal nevét, a lépés számát és a küldetés nevét. Képernyőkép vagy Lua-hibaüzenet segít a reprodukálásban.

## Forrás és részletek

Az addon módosítása után a legfrissebb letölthető csomag a repository gyökeréből frissíthető:

```sh
python tools/package_addon.py
```

A parancs az aktuális `MoteveGuide` mappából készít ellenőrzött ZIP-et, lecseréli a `downloads/MoteveGuide.zip` fájlt, eltávolítja a régi verziószámos addoncsomagokat ebből a mappából, és frissíti a README verzióját. Feltöltéskor a forrást, a ZIP-et és a README-t együtt kell commitolni.

- [Az addon forrása és teljes változásnaplója](MoteveGuide/README.md)
- [Zónák és útvonalak](MoteveGuide/ZONES.md)
- [Grafikai elemek forrásai](MoteveGuide/ARTWORK.md)
- [Küldetésadatok forrásmegjelölése](MoteveGuide/SOURCES.md)

A régi útvonalak küldetésadatai a Questie / QuestieDB projektből származnak; a származtatott útvonaladatokhoz GPL-3.0 forrásmegjelölés tartozik. A `*_rxp` útvonalak a [RestedXP/RXPGuides](https://github.com/RestedXP/RXPGuides) ingyenes WoW Forever guide-jaiból készültek, módosítva, CC BY-NC-SA 4.0 licenccel (nem kereskedelmi felhasználás; `MoteveGuide/RXP-LICENSE`). A **Barlow** és **Marcellus** betűtípusok SIL Open Font License alatt érhetők el; a licencfájlok a `MoteveGuide/Fonts/` könyvtárban találhatók. A grafikai elemek eredetét az artwork-leírás dokumentálja.

Tesztek: `python3 -m unittest discover -s tests` (a konverter és a csomag), valamint `lua5.1 tests/lua/run.lua` (útvonalválasztás és léptetés WoW API-csonkokkal; a Python-teszt is lefuttatja, ha van Lua a gépen). A 0.7.2 útvonaljavításait (repülési pontok, Tauren quest-sorrend) a `python tools/check_routes.py`, a mentett lépések átszámozását a `python tools/check_step_migration.py` ellenőrzi. Élő WoW-kliensben a RestedXP-útvonalak és a legutóbbi javítások még ellenőrzendők.
