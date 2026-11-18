# Wiki Update

Atnaujina `wiki/` layer'į pagal pakeitimus, kurie buvo padaryti per PRD/tasks ciklą: $ARGUMENTS

## Tikslas

Po PRD'o ar `/process-tasks` / `/process-tasks-batch` užbaigimo — sintetizuoti pakeitimus į living wiki:

- Naujos arba paliestos `wiki/concepts/<feature>.md`
- Atnaujintos `wiki/entities/<system>.md` jei pasikeitė architektūra
- Naujas įrašas `wiki/log.md`
- Atnaujintas `wiki/index.md` (cross-link'ai)

## Kada paleisti

| Trigger | Kontekstas |
|---|---|
| Po `/create-prd` | Sukurti placeholder concept iš PRD title + summary |
| Po `/process-tasks-batch` (paskutinės main task pabaiga) | Sintetizuoti, kas pasikeitė |
| Po stambaus refaktoringo | Atnaujinti paveiktus entities |
| Rankiniu būdu — `/wiki-update <topic>` | Ad hoc sintezė |

## Workflow

1. **Surinkti kontekstą:**
   - `git log --oneline main..HEAD` — kas buvo pakeista (commit'ai)
   - `git diff main..HEAD --stat` — paveikti failai
   - Paskutinis PRD/task failas iš `docs/requirements/` arba `docs/tasks/`
   - `wiki/index.md` — egzistuojantys puslapiai (kad nepakartoti)

2. **Nustatyti, kas turi pasikeisti:**
   - **Naujas concept** — jei featur'o nėra `wiki/concepts/`. Reikia: pavadinimas, paskirtis, susiję moduliai, cross-link'ai.
   - **Atnaujintas concept** — jei concept egzistuoja, bet pakeitimai pakeitė elgseną. Pridėti revision'ą frontmatter'yje (`updated:` data).
   - **Atnaujintas entity** — jei pasikeitė architektūra (nauja lentelė, naujas servisas, pasikeitė auth flow).
   - **Naujas synthesis** — jei užbaigta visa fazė (pvz., NT_vertinimas_darbu_planas.pdf 2 fazė) → `wiki/synthesis/faze-N.md`.

3. **Rašyti pagal konvenciją:**
   - Kebab-case failo pavadinimai
   - Privalomas frontmatter:
     ```markdown
     ---
     type: concept | entity | synthesis | source
     created: YYYY-MM-DD
     updated: YYYY-MM-DD
     sources:
       - <git ref / file paths / PRD nuoroda>
     ---
     ```
   - Cross-link'ai: `[[wiki/entities/<name>]]` arba `[[wiki/concepts/<name>]]`
   - LT kalba (ne EN), išskyrus code identifier'ius

4. **Atnaujinti `wiki/index.md`:**
   - Pridėti naujus puslapius prie atitinkamos sekcijos (Entities / Concepts / Sources / Synthesis)
   - Su trumpu (≤80 simbolių) aprašymu

5. **Įrašyti `wiki/log.md` įrašą:**
   ```markdown
   ## YYYY-MM-DD — <prd | task-batch | refactor | manual>

   **Šaltinis:** <PRD/task path arba commit'ai>
   **Veiksmas:** <santrauka>
   **Paveikti puslapiai:**
   - <sąrašas>

   **Naujos įžvalgos:** <viena eilutė — kas vertinga ateities sesijoms>
   ```

6. **Verifikuoti:**
   - `ls wiki/entities/ wiki/concepts/ wiki/synthesis/` — visi failai egzistuoja
   - `grep -r "wiki/<new-page>" wiki/` — index'e ir log'e yra cross-link'ai

## Sintezės principai

- **Tikslumas > pilnumas.** Geriau trumpas tikslus įrašas, nei ilgas spekuliatyvus.
- **Code-truth.** Visi konkretūs faktai (funkcijų vardai, file path'ai, konstantos) turi būti perskaityti iš source kodo, ne išgalvoti.
- **Cross-link'ai.** Kiekvienas naujas puslapis turi bent 2 `[[wiki/...]]` nuorodas — kitaip puslapis bus orphan'as.
- **Living document.** Concept'ai gali būti atnaujinami daug kartų — tik praplėsk `updated:` datą ir prirask pakeitimus, neperrašyk istorijos.

## Output

Pranešk vartotojui kompaktiškai:

```
Wiki update baigtas:

Sukurti puslapiai:
- wiki/concepts/<name>.md (concept)
- wiki/synthesis/<name>.md (synthesis)

Atnaujinti puslapiai:
- wiki/entities/<name>.md (sources atnaujinti)
- wiki/index.md (3 nauji cross-link'ai)
- wiki/log.md (1 naujas įrašas)

Cross-link'ai patikrinti, orphan'ų nėra.
```

## Pastabos

- **Niekada nemodifikuok `MEMORY.md`** (auto-memory) per šią komandą. Auto-memory yra atskiras sluoksnis, valdomas AI sprendimu pagal feedback/preferencijas.
- **Niekada nemodifikuok `entities.json`** rankiniu būdu — jį tvarko `mempalace mine`.
- Po wiki update'o — `mempalace mine .` paleidžiamas Stop hook'e automatiškai, todėl naujos wiki failai pateks į palace iki kitos sesijos.
