# AGENTS.md

Tai kanoninis projekto instrukcijų failas visiems AI agentams: Codex jį skaito tiesiogiai, o Claude Code įsikelia per `@AGENTS.md` importą CLAUDE.md faile. Vienas tiesos šaltinis - jokių kopijų ir veidrodžių.

> **Apimties taisyklė:** failas aprašo dabartinę projekto būseną, ne istoriją. Pakeitimų istorija gyvena CHANGELOG ir `wiki/log.md`, gilūs feature aprašymai - `wiki/` puslapiuose. Orientyras - iki 150 eilučių; Codex failą nukerta ties 32 KiB.

## Project Overview

`obuolys` - naujas projektas, kurio kodas dar nepradėtas. Paskirtis ir stack'as bus aprašyti, kai atsiras pirmasis kodas (per `/po-create-prd` ir `/po-adapt`).
UI kalba: Lietuvių.

## Commands

Komandų dar nėra - projekte nėra kodo ir build įrankio. Kai jos atsiras, įrašyk jas čia ir `.po-config.json` `config.*` laukuose. Nekurk neegzistuojančių komandų.

## Tech Stack

Dar nepasirinktas. Nedaryk prielaidų apie konkrečias bibliotekas, kol jų nematei repo.

## Architecture

Dar nėra. Aprašyk sluoksnius ir duomenų srautą, kai atsiras kodas.

## Conventions

- **UI kalba**: Lietuvių. Vartotojui matomi tekstai, klaidos ir toast'ai - lietuviškai. Kodo identifikatoriai, komandos ir API parametrai lieka EN.
- **Aplinkos kintamieji**: tik vardai dokumentacijoje, niekada ne reikšmės; `.env` failai necommit'inami.

## Working Principles

- **Taisyk visas problemas, kurias sutinki** - jei randi sugedusį config, lint klaidą ar bug'ą darbo metu, taisyk iškart, nesvarbu ar tu jį sukūrei. Niekada nenurašyk problemų kaip „jau egzistavusių".
- **Po pakeitimų paleisk lint plius build** - patikrink, kad linter ir build praeina prieš užbaigiant.
- **Niekada savarankiškai nedaryk `git commit` ar `git push`** - pakeitimus įgyvendink ir pasiūlyk, bet commit'ą/push'ą atlik tik vartotojui aiškiai paprašius arba patvirtinus. (Claude pusėje tai papildomai saugo permission safety-rails; ši tekstinė taisyklė galioja ir harness'ams, kurie permissions nemato.)
- **Parodyk rezultatą, ne tik kodą.** Baigęs funkciją ar didesnį vartotojui matomą pakeitimą, paleisk `/po-report` (Codex: `$po-report`): ataskaita paprasta kalba su ekrano nuotraukomis ir instrukcija, kaip išbandyti pačiam. Mažam pakeitimui pakanka dviejų sakinių: ką vartotojas pamatys ir kaip tai patikrinti.
- **Po kiekvieno push'o į produkcinę šaką paleisk `/po-deploy-check`** (Codex: `$po-deploy-check`): ar diegimas pavyko, ar svetainė atsidaro, ar serveris nemeta naujų klaidų. Apie gedimą pirmas turi sužinoti vartotojas, ne jo klientai.

## Bendravimas su vartotoju

- **Bendravimo kalba: lietuvių (numatyta).** Paaiškinimai, atsakymai ir klausimai vartotojui - taisyklinga lietuvių kalba su diakritikais. Kodo identifikatoriai, komandos ir techniniai terminai lieka originalūs. (Tai NE tas pats kas „UI kalba" Conventions sekcijoje.)
- **Paaiškink ne tik „ką", bet ir „kodėl".** Venk nepaaiškinto žargono; neišvengiamą terminą paaiškink vienu paprastu sakiniu iškart.
- **Priimant sprendimą - duok aiškią rekomendaciją** ir praktiškai paaiškink, ką kiekvienas variantas reiškia, o ne tik jų pavadinimus.
- **Sąžiningumas svarbiau už pritarimą.** Jei vartotojas klysta techniškai, pasakyk tai pagarbiai ir paaiškink kodėl. Klaidas pripažink ramiai, be besaikio atsiprašinėjimo.
- **Formatavimas: tiek, kiek reikia aiškumui.** Paaiškinimus rašyk proza, trumpomis pastraipomis; lenteles ir sąrašus palik struktūruotam techniniam turiniui.
- **Bloką ar kritiką perduok tvirtai, bet pagarbiai.** Guard ar audito BLOCK verdiktas ir įrodymai lieka tvirti; paaiškink kas negerai, kodėl ir ką daryti toliau.

## Wiki sluoksnis

- `wiki/` yra living dokumentacija (entities, concepts, sources, synthesis).
- **PRIEŠ skenuodamas kodo bazę, pirmiausia perskaityk `wiki/index.md`** ir atsirink 3-5 relevantiškus puslapius (Wiki Context Load protokolas). Wiki puslapiai yra pirmas kontekstinis šaltinis - jie atstoja didelę dalį kodo skenavimo.
- Atnaujinama per `/po-wiki-update`. Stop hook'as `wiki-drift-stop.sh` aptinka drift'ą tarp kodo ir `wiki/log.md`.
- Sintetizuok su `[[wiki/...]]` cross-link'ais.

## Codex pastabos

- Rizikingą ar daugelio failų darbą pradėk plan režimu.
- Shell, tinklo, MCP ir failų teises laikyk minimaliame patvirtintame lygyje.
- Verifikacijos komandas imk iš šio failo Commands sekcijos; nespėliok ir nekurk komandų.
- Griežtos taisyklės (guard'ai, pre-commit gate, Stop hook'ai) veikia hook ir CI sluoksnyje; ši proza jų nepakeičia ir jų neapeina.
