---
type: log
created: 2026-11-10
updated: 2026-11-10
---

## 2026-11-10 - wiki inicializuota

**Šaltinis:** projekto scaffold (`ponas-obuolys` plugin templates).

**Veiksmas:** sukurtas pradinis `wiki/` sluoksnis - `index.md` katalogas plius tuščios `concepts/`, `entities/`, `sources/`, `synthesis/` sekcijos. Šis įrašas yra drift hook'o baseline.

**Paveikti puslapiai:**
- `wiki/index.md` - katalogo skeletas
- `wiki/log.md` - šis įrašas

**Naujos įžvalgos:** `wiki-drift-stop.sh` Stop hook'as seka commit'us nuo paskutinio `wiki/log.md` įrašo. Šis pradinis įrašas paverčia hook'ą aktyvų. Pirmas commit'as, palietęs ne-wiki failus, paskatins paleisti `/po-wiki-update`.

---

## 2026-11-10 - drift baseline (81081bb)

**Šaltinis:** `/po-init` bootstrap esamoje repozitorijoje (HEAD `81081bb`).

**Veiksmas:** wiki/docs drift skaičiuojamas nuo šio momento, ne nuo repo pradžios. Sukurtas [[wiki/entities/obuolys]] puslapis.

---
