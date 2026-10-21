# Moteve Guide

Horde és Alliance fejlődési útvonalak WoW Foreverhez, 1–30-as szintig.

**Aktuális verzió: 0.6.4**

[Az addon letöltése (ZIP)](downloads/MoteveGuide-0.6.4.zip?raw=true)

## Telepítés

1. Töltsd le és csomagold ki a fenti ZIP-et.
2. Másold a `MoteveGuide` mappát a játék `Interface/AddOns/` könyvtárába. A tesztelt telepítési hely: `_classic_beta_/Interface/AddOns/MoteveGuide/`.
3. Az addonlistán engedélyezd a Moteve Guide-ot. Frissítés után írd be: `/reload`.

A ZIP-ben lévő mappanevet tartsd meg: a `MoteveGuide.toc` közvetlenül a `MoteveGuide` mappában legyen.

## Funkciók

- Horde és Alliance útvonalak, zónaválasztóval, 1–30-as szintig.
- Aktuális és következő feladatok, küldetéscélok előrehaladásával.
- Irányjelző nyíl, távolság és térképes célpont.
- Automatikus léptetés: a már teljesített lépéseket átugorja a következő teendőig.
- Korábbi lépések visszanézése a bal nyíllal és kétirányú görgetéssel.
- Négy függetlenül választható ablak- és nyílkinézet: Eredeti, Minimal, Classic Light, Glass. Új beállításoknál a Glass az alapértelmezett.
- Átméretezhető ablak, XP/óra kijelzés, állítható számú következő lépés.
- Automatikus küldetésfelvétel és -leadás, kikapcsolható beállítással.
- Magyar ékezeteket támogató betűtípusok a panelen és a súgóbuborékokban.

## Parancsok

| Parancs | Művelet |
| --- | --- |
| `/mg` | Ablak megjelenítése / elrejtése |
| `/mg opciok` | Beállítások megnyitása |
| `/mg prev` | Előző lépés megtekintése |
| `/mg next` | Következő teendő / aktuális lépés kihagyása |
| `/mg nyil` | Irányjelző be- és kikapcsolása |
| `/mg scale 70` | Ablakméret beállítása százalékban |

## Forrás és részletek

- [Az addon forrása és teljes változásnaplója](MoteveGuide/README.md)
- [Zónák és útvonalak](MoteveGuide/ZONES.md)
- [Grafikai elemek forrásai](MoteveGuide/ARTWORK.md)

A mellékelt betűtípusok licencfájljai a `MoteveGuide/Fonts/` könyvtárban találhatók. A küldetésadatok forrásmegjelölései az addon dokumentációjában szerepelnek.

A 0.6.4-es csomag helyi Lua teszteken ellenőrizve (kinézetek, léptetés, útvonalak, méretezés, súgók és magyar karakterek). Élő WoW-kliensben a legutóbbi javítások még ellenőrzendők.
