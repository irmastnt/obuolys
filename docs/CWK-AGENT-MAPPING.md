# CWK Agent Mapping

CWK (Claude Workflow Kit) 4 etapų pipeline komandos (`/create-prd`, `/generate-tasks`, `/process-tasks`, `/process-tasks-batch`) buvo port'intos į šį starter kit'ą. Originalus CWK savo guard'us vadino EN konvencija. **Šiame starter kit'e tie pavadinimai pakeisti į starter'io 7 LT guard'us** dar port'inimo metu. Žr. `scripts/port-cwk.sh`.

Šis failas dokumentuoja atitikmenis. Jei dalyvis grįš į originalų CWK, jam bus aiškiau, kas į ką pakeista.

## Guard'ų pavadinimų atitikmenys

| CWK originalas (EN) | Starter atitikmuo (LT) | Funkcija |
|---|---|---|
| `payment-guardian` | `payment-guard` | Stripe idempotency, kainų logika, webhook signatures |
| `db-guardian` | `db-migration-guard` | Destruktyvių migracijų blokavimas, rollback validacija |
| `lang-reviewer` | `language-guard` | LT, EN konvencijų atitikimas (UI lietuviškai, kodas angliškai) |
| `file-splitter` | `file-size-guard` | Failai iki 300 LOC, funkcijos iki 50 LOC |
| `risk-assessor` | `risk-assessor` | Vienodi. Žemos, vidutinės, aukštos rizikos vertinimas PR'ams |

## Starter'io ekstra guard'ai (CWK neturi)

Starter kit'e du papildomi guard'ai. CWK pipeline komandos jų tiesiogiai necituoja, bet jie veikia kaip `pre-commit` apsauga:

| Starter guard | Funkcija |
|---|---|
| `security-guard` | Secret nutekėjimai (`.env*`, raktai), RLS spragos, CSP, open redirect, SSRF |
| `test-coverage-guard` | Testų coverage bent 80% paveiktiems failams. E2E privalomi kritiniam flow'ui |

## CWK guard'ai, kurių NEport'inome

CWK turi 8 guard'us. Penki iš jų yra lentelėje viršuje. Likę trys **neportuoti**, nes jų funkcionalumą dengia kiti mechanizmai:

| CWK guard'as | Kodėl neportuotas |
|---|---|
| `pre-deploy` | Funkcionalumą dengia `scripts/verify.sh` ir `.github/workflows/self-heal.yml` |
| `dependency-guardian` | `npm audit` ir kiti dependency check'ai dengia `security-guard` |
| `test-quality-guardian` | Persidengia su starter'io `test-coverage-guard` |

## Skill'ų referencijos

CWK komandos kelis kartus mini `superpowers:test-driven-development` ir kitus skill'us. Šie skill'ai yra **opcionalūs**:

- Jei dalyvis turi įdiegtą `superpowers` plugin'ą, komandos jį naudos automatiškai.
- Jei ne, komandos veiks be skill'o pagalbos. Tai nėra klaida.

Port'inimo skriptas pažymi tokias referencijas kaip `(optional)`, kad dalyvis suprastų situaciją.

## Path'ų konvencijos

CWK originale PRD ir tasks failai gyvena čia:

- `tasks/prd-{slug}.md` (PRD)
- `tasks/tasks-prd-{slug}.md` (task list)

Starter kit'as port'inimo metu pakeičia tas vietas į savąsias:

- `docs/requirements/REQ-YYYY-MM-DD-NNN-{slug}.md` (PRD)
- `docs/tasks/TASK-{slug}.md` (task list)

Šie path'ai atitinka starter'io `CLAUDE.md` §2.1 numatytą struktūrą.

## Kaip atnaujinti komandas po CWK release'o

Jei CWK upstream'as (`/Users/auris/Documents/GitHub/claude-workflow-kit/commands/`) atnaujinamas, paleiskite:

```bash
bash scripts/port-cwk.sh
```

Skriptas sugeneruoja `.claude/commands/_templates/` iš naujo. Patikrina, kad nelieka senų EN guard vardų ar `tasks/` path'ų. Dalyvio `setup.sh` paskui perkurs `.claude/commands/*.md` su jo stack'ui pritaikytomis komandomis.

`_templates/` turi būti commit'inta. `.claude/commands/*.md` ignoruojami git'e, nes juos sugeneruoja `setup.sh`.
