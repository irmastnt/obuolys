---
type: index
created: 2026-04-25
updated: 2026-04-25
---

# Wiki · Puslapių katalogas

Šis failas yra jūsų wiki turinio lentelė. Memoriki / Claude Code pats ją atnaujina, kai ingestuoja naujus šaltinius iš `raw/`.

**Neredaguokite rankiniu būdu** — viskas atnaujinama per `mempalace mine .` arba Claude Code užklausą "atnaujink wiki".

## Entities (žmonės, kompanijos)

_(Kol nėra įkelta jokių šaltinių)_

## Concepts (idėjos, framework'ai, terminai)

_(Kol nėra įkelta jokių šaltinių)_

## Sources (išoriniai šaltiniai)

_(Kol nėra įkelta jokių šaltinių)_

## Synthesis (kryžminė analizė)

_(Kol nėra įkelta jokių šaltinių)_

---

## Kaip tai veikia

1. Įmesite failą į `raw/` (pvz., `raw/stripe-api-notes.md`).
2. Claude Code perskaito failą, išskaido į entities + concepts.
3. Sukuria puslapius `wiki/entities/<name>.md` ir `wiki/concepts/<name>.md`.
4. Atnaujina šį indeksą.
5. Įrašo operaciją į `wiki/log.md`.

**Užklausos metu** — Claude Code ieško per šį indeksą, atranda relevant puslapius, ir sintezuoja atsakymą su cross-links.
