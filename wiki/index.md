---
type: index
created: 2026-11-10
updated: 2026-11-10
---

# Wiki · Puslapių katalogas

Šis failas yra wiki turinio lentelė. Claude Code atnaujina ją, kai sukuria naujus entity arba concept puslapius, arba ingestuoja naujus šaltinius.

**Pildoma per `/po-wiki-update` komandą.** Stop hook'as (`wiki-drift-stop.sh`) aptinka drift'ą tarp commit'ų ir `wiki/log.md`. Jis reikalauja paleisti `/po-wiki-update`, kol drift'as neištaisytas.

## Frontmatter konvencija

Kiekvienas wiki puslapis turi privalomą frontmatter bloką:

```markdown
---
type: concept | entity | source | synthesis
created: 2026-11-10
updated: 2026-11-10
sources:
  - <git ref / file paths / PRD nuoroda>
---
```

- Failo vardai: kebab-case (pvz. `auth-flow.md`).
- Cross-link'ai: `[[wiki/entities/<name>]]` arba `[[wiki/concepts/<name>]]`.
- Turinys projekto UI kalba (numatyta: Lietuvių). Kodo identifikatoriai, komandos ir API parametrai lieka EN, backtick'uose.

## Entities (žmonės, kompanijos, sistemos)

- [[wiki/entities/obuolys]] - pats projektas: paskirtis, stack, workflow

## Concepts (idėjos, framework'ai, terminai)

_(Tuščia. Pildoma per `/po-wiki-update`, kai atsiranda pirmas concept puslapis.)_

## Sources (išoriniai šaltiniai)

_(Tuščia. Pildoma per `/po-wiki-update`, kai ingestuojamas pirmas šaltinis.)_

## Synthesis (kryžminė analizė)

_(Pridedama, kai entity/concept tinklas tampa pakankamai tankus kryžminei analizei.)_

---

## Kaip tai veikia

1. Claude Code perskaito pakeitimus (commit'us, PRD/tasks failus) ir atskiria entities plius concepts.
2. Sukuria arba atnaujina puslapius `wiki/entities/<name>.md`, `wiki/concepts/<name>.md`, `wiki/sources/<name>.md`.
3. Atnaujina šį indeksą su nauju cross-link'u kiekvienam puslapiui.
4. Įrašo operaciją į `wiki/log.md`.

**Užklausos metu** Claude Code ieško per šį indeksą, atranda relevant puslapius ir sintetizuoja atsakymą su cross-link'ais (`[[wiki/...]]` formatu).
