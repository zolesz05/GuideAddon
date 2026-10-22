# Moteve Guide 0.7.2

Saját Horde és Alliance leveling útvonalak WoW Foreverhez, RestedXP-szerű működéssel.

## 0.7.2 – javított Horde útvonalak (Tauren, Orc / Troll, Undead)

- Nincs több repülési pont felvétele ott, ahol a kliensben nincs flight master: Bloodhoof Village (Seikwa), Razor Hill (Shoja'my) és Brill (Morganus). Ezek a lépések korábban csak kézi átugrással tűntek el.
- Tauren útvonal: az **A Task Unfinished** quest a Camp Narache és Bloodhoof Village közötti úton jelenik meg (Antur Fallow), a leadása Innkeeper Kauthnál rögtön a Bloodhoof Village-be érkezéskor, nem Thunder Bluff után.
- A `tools/check_routes.py` ellenőrzi, hogy minden repülési pont létezik a célkliensben.
- A már elkezdett karakterek mentett lépése és kézi átugrásai az első belépéskor egyszer átszámozódnak, így a Guide ugyanott folytatódik; a törölt repülési pont átugrása nem öröklődik a helyére került lépésre. Ezt a `tools/check_step_migration.py` ellenőrzi.

## 0.7.1 – karika nélküli nyilak, Moteve alapértelmezés

- Egyik nyílkinézet sem mutat körgyűrűt, iránytűkeretet vagy kör alakú hátteret. A mutató, távolság és megérkezési pipa megmarad.
- Új, hiányzó vagy hibás kinézetbeállításnál a Moteve az alapértelmezett az ablakhoz és a nyílhoz is. A már elmentett érvényes választásokat megtartja.

## 0.7.0 – a chathez és damage meterhez illő Moteve kinézet

- Ötödik, külön választható ablak- és nyílkinézet: **Moteve**. A beállításokban a meglévő négy stílus mellett jelenik meg.
- A Moteve Chat és Moteve Damage Meter színeit használja: áttetsző sötétkék háttér, finom kék szegély, lila aktív jelölő és XP-sáv, cián célkitűzéssáv, mentazöld teljesített célok.
- Marcellus címek és magyar ékezeteket támogató Barlow szövegek. A hátteret a chathez hasonló függőleges áttűnés teszi visszafogottá.
- A nyíl cián mutatót és lilás áttetsző hátteret kap; a távolság, irányszámítás és megérkezési pipa változatlanul működik.
- Az ablak és a nyíl egymástól függetlenül állítható, összesen 25 párosítással. A választógombok öt stílusnál is elférnek a panelen.
- A Glass marad az alapértelmezett; a meglévő választásokat megtartja. A stílushoz nem szükséges a Chat vagy a Damage Meter külön telepítése.

## 0.6.4 – magyar ékezetek a súgóbuborékokban

- A guide saját súgóbuborékot használ Barlow betűtípussal, az ő/ű/Ő/Ű betűk helyes megjelenítéséhez.
- A navigációs gombok, fejléc, küldetéssorok, XP, méretezés és beállítások súgói is ezt használják. A küldetéscélok jobb oldali számoszlopát is kezeli.
- A játék közös GameTooltip betűtípusait nem módosítja. A fejléc súgója jelzi a visszafelé görgetést is.

## 0.6.3 – magyar ékezetek a beállításokban

- A beállítópanel feliratai a mellékelt Barlow betűtípust használják, amely tartalmazza az ő/ű/Ő/Ű betűket is.
- A gombok normál, kiemelt és letiltott feliratai is saját Barlow betűobjektumot kapnak. A játék és a többi addon betűtípusait nem módosítja.

## 0.6.2 – Glass alapértelmezett kinézet

- Új vagy hiányzó beállításoknál az ablak és a nyíl is Glass kinézettel indul. Hibás kinézetértéknél is Glassra áll vissza.
- A korábban elmentett, érvényes kinézetválasztásokat megtartja. A többi stílus továbbra is választható a beállításokban.

## 0.6.1 – visszanézhető lépések és automatikus továbblépés

- A bal nyíl és a `/mg prev` a korábbi, akár már teljesített lépést is megmutatja. Az események és a frissítés nem ugranak el róla visszanézés közben.
- Az egérgörgővel mindkét irányban böngészhető a lista, a korábbi teljesített lépések is elérhetők. A görgetés önmagában nem változtatja meg az aktuális feladatot vagy a nyíl célját.
- Bal kattintás egy korábbi soron: visszanézés. A jobb nyíllal vagy `/mg next` paranccsal folytatható a haladás; a kész lépéseket átugorja a következő teendőig.
- Normál haladás közben a küldetésnapló változásakor automatikusan átugorja az előre teljesített lépéseket is. A kész célkitűzés után a még le nem adott küldetés leadásánál megáll.
- A visszalépés nem törli a teljesítéseket vagy a kézi kihagyásokat. A következő gomb továbbra is kihagyja az éppen nyitott, még nem teljesített lépést.
- Helyi Lua tesztek ellenőrzik a visszanézést, a görgetést, a kész láncok átugrását és az útvonal végét; élő kliensben még ellenőrizni kell.

## 0.6.0 – váltható ablak- és nyílskinek

Beállítások → AddOns → Moteve Guide, vagy `/mg opciok`.

- **Guide ablak kinézete:** Eredeti, Minimal, Classic Light, Glass.
- **Irányjelző nyíl kinézete:** Eredeti, Minimal, Classic Light, Glass.
- A két választó független; mind a 16 kombináció használható. A kiválasztott gomb neve szögletes zárójelben látszik.
- Azonnal vált, újratöltés nélkül. A választás a MoteveGuideDB-ben megmarad; a 0.6.2 verziótól a Glass az alapérték.
- Minimal: sötét sík panel, tiszta Barlow szöveg, vékony szegély és visszafogott zöld kiemelés.
- Classic Light: vékony bronzszegély, meleg sötét háttér és klasszikus címbetű, nagy díszek nélkül.
- Glass: áttetsző szürkéskék felület, finom keret és apró aktív jelölő. Valódi háttérelmosást nem alkalmaz.
- Az új nyilak külön textúrán kezelik a forgó mutatót és a rögzített iránytűt / áttetsző körlapot. A távolság yardban látszik; megérkezéskor pipa jelenik meg. A régi nyíl változatlanul választható.
- Az új ablakok jobb felső háromvonalas gombja is megnyitja a beállításokat. A beállítópanel kisebb ablakban görgethető.
- A választás nem állítja át az útvonalat, a kihagyott lépéseket, az ablak helyét vagy méretét.

Helyileg ellenőrizve: 16 kombináció, beállításgombok, mentés és hibás érték javítása, az eredeti stílus visszaállítása, irány/megérkezés és hiányzó pozíció, valamint a korábbi felület-, útvonal- és méretezési tesztek. A látvány a tényleges widgetekből készült helyi renderen is ellenőrizve; a WoW kliensben még ellenőrizni kell.

## 0.5.0 – mindkét frakció és a többi zóna 30-ig
- 32 új, önálló zónaútvonal 23 zónához, összesen 962 különböző questazonosítóval.
- Három új Alliance főútvonal: Human, Dwarf/Gnome, Night Elf, 1–30-ig; új karakteren fajtól függően automatikusan választ.
- A három korábbi Horde útvonal és lépésszámozás változatlan; a meglévő haladásod megmarad.
- Jobb klikk a fejlécen → lapozható útvonalválasztó; a másik frakció új útvonalai nem látszanak.
- Beállítások → Útvonal / zóna kiválasztása; a választó tíz útvonalat mutat oldalanként.
- A zónák és a hozzájuk tartozó parancsok a ZONES.md fájlban találhatók.
- Questelőfeltételek, fajkorlátozások és kizáró questek ellenőrzése az új adatoknál. Hiányzó előfeltételnél a még fel nem vett questet átugorja; egy szinttől újrakezdett lánchoz korábbi előquestek szükségesek lehetnek.
- Az utazási/figyelmeztető lépést a Következő gombbal zárhatod. A zónaváltásoknál tényleges NPC-koordinátára vezet a nyíl; hajó- és repülőjárat-útvonalat nem tervez.

### Lefedettség és ellenőrzés
A generált adatok a helyben telepített QuestieDB Forever 1.0.5 kiadásból származnak. Az általános, kültéri questek kerültek az új csomagba; kaszt-, szakma-, ismételhető, feltételes, illetve nem igazolt kültéri célpontú láncok kimaradnak. Küldetésenkénti útvonal, nem optimalizált speedrun. Az automatikus szintgát megállít, ha a következő feladathoz még kevés a szinted; másik zónával vagy grindre váltva folytathatsz.

Alterac, Arathi, Stranglethorn és Desolace csak a 30-as szintig felvehető kezdőszakaszokat tartalmazzák. A quest ajánlott szintje akár 35 is lehet; a játékban látható nehézséget vedd figyelembe. A többi zónánál is lehetnek alternatív, egymást kizáró láncok. A 30-as szinthez szükség lehet kiegészítő questekre vagy grindre.

Helyi adatellenőrzés: questazonosítók, faj/frakció, előquestek sorrendje, koordináták, felvétel/leadás párok, legfeljebb 30-as szintgátak és az eredeti adatok megőrzése. Lua-szimuláció: faj szerinti választás, lapozás, előfeltételek, a meglévő felület és átméretezés. A teljes útvonalakat még nem jártuk végig játékban.

Az új generátor és az adatforrás másolata külön forráscsomagban érhető el (MoteveGuide-0.5.0-sources.zip). QuestieDB/Questie adatok: GPL-3.0, az eredeti szerzők feltüntetésével; lásd a forráscsomag SOURCES.md fájlját.

## 0.4.1 – állítható ablakméret
- A jobb alsó sarok fogantyúját bal gombbal húzva arányosan méretezhető az egész ablak.
- A mérettartomány 55–130%; az új alapméret 85%, azaz 357 UI-egység szélesség.
- Pontos beállítás: `/mg scale 70` vagy `/mg meret 70` = 70%.
- Jobb klikk a méretezőfogantyún: visszaállítás 85%-ra.
- A méretet megjegyzi; questfrissítés és újrabelépés után is megmarad.
- Az előre látható sorok száma a meglévő Beállítások menüben csökkenthető.

## Útvonalak (fajtól függően automatikusan)
- **Orc / Troll:** Durotar 1–12 → Barrens 12–20
- **Undead:** Tirisfal 1–11 → Silverpine 11–15 → Barrens 15–20
- **Tauren:** Mulgore 1–11 → Barrens 11–20
- **Közös rész:** Barrens 20–22 → Stonetalon 22–24 → Ashenvale 24–27 → Thousand Needles 27–30

## Mit csinál
- Ablakban mutatja az aktuális lépést és a következőket; egérgörgővel előre és vissza is lapozható. Előrefelé a már kész lépések rejtve maradnak, a korábbiak visszanézhetők.
- Magától lép tovább, ha felvetted, megcsináltad vagy leadtad a questet.
- Irány-nyíl távolsággal, és a térképen is beállítja a célt.
- Az útvonal questjeit automatikusan felveszi és leadja. **Shift** nyomva tartásával kikapcsol. Ha több jutalom közül kell választani, azt neked kell.
- XP/óra, hány perc a szintlépésig, rested XP.
- Jobb klikk az ablak tetején: útvonal- és zónaváltó menü (ugrás bármelyik szakasz elejére).
- Questek haladása: az aktuális lépésnél sávonként (pl. 4/12), a többinél röviden; zöld, ha kész.
- Bal klikk egy soron: ez legyen az aktuális. Jobb klikk: kész / kihagy.

## Parancsok
`/mg` ablak ki/be · `/mg next` · `/mg prev` · `/mg reset` · `/mg guide orctroll|undead|tauren` · `/mg nyil` · `/mg auto` · `/mg opciok`

Beállítások: Options → AddOns → Moteve Guide.

## Tudnivalók
- Az útvonalat program generálta a quest-adatbázisból. Még nincs játékban végigtesztelve, ezért lehetnek benne fura sorrendek.
- Stonetalonban és Ashenvale-ben kevés a quest, ott több a grind.
- Utazási és hearthstone lépések még nincsenek benne.

## Credits
A quest-, NPC- és koordinátaadatok a [QuestieDB](https://github.com/Questie/Questie) projektből származnak (GPL-3.0). A betűtípusok Barlow és Marcellus (SIL OFL). A RestedXP fizetős guide-jaiból semmi nincs benne.


## 0.4.0 – bronzkeretes megjelenés
Új, részletes bronz- és bőrtextúrák, szarvdíszek és vörös zászlók a kapott referenciakép alapján.
Arany questikonok, ezüst kard, zöld aktív sor és a szöveg alá igazított haladássávok.
Szélesebb, 420 UI-egységes ablak; a magassága a látható sorokhoz és célokhoz igazodik.
A questadatok és a mentett útvonal-haladás változatlanok. A grafika ImageGen segítségével készült.

### Telepítés / frissítés
1. Lépj ki a játékból.
2. A ZIP-ben lévő `MoteveGuide` mappával cseréld le a játék `Interface/AddOns/MoteveGuide` mappáját.
3. A karakterválasztón engedélyezd a Moteve Guide addont. A csomag az eredeti Interface: 16001 értéket használja.
4. Belépés után `/mg` kapcsolja az ablakot; jobb klikk a fejlécen nyitja az útvonalmenüt.
A WTF mappát ne töröld, ott vannak a korábbi beállításaid és a haladásod.

### Ellenőrzés
A helyi ellenőrzés a csomag szerkezetére, Lua betöltésére és tesztkörnyezetben futtatott felületi állapotokra terjed ki.
A mellékelt előnézet illusztráció. A WoW Forever kliensben külön ellenőrizendő a tényleges megjelenés.
