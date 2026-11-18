---
name: karpathy-principles
description: Use when about to write, modify, or delete code. Enforces the 4 Karpathy anti-LLM-mistake principles — think before coding, simplicity first, surgical changes, goal-driven execution. Invoke before any code change, especially for refactors, bug fixes, or feature implementation.
---

# Karpathy Principles

Andrej Karpathy pastebėjo 4 pasikartojančias LLM klaidas programuojant:
1. **Spėja** — užuot paklausę, išgalvoja atsakymą.
2. **Per daug sudėtina** — prideda abstrakcijų, kurių niekas neprašė.
3. **Keičia ko nereikia** — "pakelia" gretimą kodą prabėgomis.
4. **Dirba be sėkmės kriterijaus** — "turėtų veikti" ≠ testuojama.

Šis skill — keturių principų antidotas.

## Principas #1 — Think Before Coding

**Prieš rašant kodą:**
- Deklaruok prielaidas. Jei yra dvi interpretacijos — parodyk abi, neapsispręsk tyliai.
- Jei paprastesnis sprendimas egzistuoja — pasakyk apie jį, net jei reikia nesutikti su užduotimi.
- Jei kažkas neaišku — **sustok ir klausk**. Nepradėk "just in case" implementacijos.

**Signalas, kad principas pažeistas:**
Rašai kodą, prieš tai nesuformulavęs vienos eilutės "mano tikslas yra X".

## Principas #2 — Simplicity First

**Minimumas kodo, sprendžiantis problemą.**

- Jokių featurų viršaus to, ko prašyta.
- Jokių abstrakcijų vienetiniam kodui.
- Jokio "flexibility" arba "configurability", kurio neprašyta.
- Jokio error handling'o neįmanomiems scenarijams.

**Testas:** "Ar senior engineer pasakytų, kad tai per daug sudėtinga?" Jei taip — perrašai.
**Kraštinis atvejis:** 200 eilučių, kai užtenka 50 → perrašai.

## Principas #3 — Surgical Changes

**Lieti tik tai, ko reikia. Valyti tik savo netvarką.**

Redaguojant esamą kodą:
- Ne "patobulink" gretimo kodo, komentarų, formatavimo.
- Ne refaktorink to, kas nesulaužyta.
- Atkartok esamą stilių, net jei tu pats darytum kitaip.
- Pastebėjai nesusijusį dead code — **paminėk, netrink** (išskyrus tau pačiam trukdantį).

Kai tavo pakeitimai sukuria orfanų (unused imports, variables):
- Pašalink TIK tuos, kuriuos sukūrė tavo pakeitimai.
- Pre-existing dead code — palik, nebent paprašyta.

**Testas:** "Ar kiekviena pakeista eilutė tiesiogiai susiejama su užduotimi?" Jei ne — pašalink pakeitimą.

## Principas #4 — Goal-Driven Execution

**Apibrėžk sėkmės kriterijus. Loop'ink kol patvirtinta.**

Konvertuok užduotis į verifikuojamus tikslus:

| Ad-hoc | Goal-driven |
|---|---|
| "Pridėk validaciją" | "Parašyk testus neteisingam įvedimui, tada praverčiam" |
| "Pataisyk bug'ą" | "Parašyk testą, kuris reprodukuoja bug'ą, tada praverčiam" |
| "Refactor X" | "Tests pass prieš ir po — kitaip rollback" |

Daugiaveiksminėms užduotims — pareikšk trumpą planą:
```
1. [Žingsnis] → verify: [patikrinimas]
2. [Žingsnis] → verify: [patikrinimas]
3. [Žingsnis] → verify: [patikrinimas]
```

Stiprūs kriterijai = gali loop'inti savarankiškai. Silpni ("make it work") = nuolat klaus vartotojo.

## Kaip taikyti

1. Prieš bet kokią kodo užduotį — perskaityk atitinkamą principą.
2. Jei principas pažeistas — **STOP**, perrašyk savo planą.
3. Po užduoties — pasitikrink: ar diff'e kiekviena eilutė paaiškinama vartotojo užklausa?

## Kraštiniai atvejai

- **Legacy kodas:** principas #3 taikomas stipriau — neliesti nieko, kas nėra scope'e, net jei "aiškiai bloga".
- **Prototypai:** principas #4 mažiau griežtas — "just explore" gali pakeisti "verify".
- **Testai:** principas #2 netaikomas testo setup'ui — ten reikia "verbose over clever".
