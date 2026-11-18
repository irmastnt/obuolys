---
type: log
created: 2026-04-25
updated: 2026-04-25
---

# Wiki · Operacijų žurnalas

Chronologinis įrašas, ką Memoriki / Claude Code atnaujino wiki'je.

## Formatas

```
## YYYY-MM-DD HH:MM - <ingest | query | lint | manual>

**Šaltinis:** raw/<file>.md (SHA: abc123...)
**Veiksmas:** <ką AI darė>
**Paveikti puslapiai:** <sąrašas>
**Naujos įžvalgos:** <viena eilutė>
```

## Žurnalas

## 2026-11-18 11:30 - manual

**Šaltinis:** sesijos darbas (be raw/ šaltinio)
**Veiksmas:** Sujungti ponas-obuolys ir CWK guard rinkiniai: git pre-commit gate'as - ponas-obuolys (lokalus secret skenas prieš AI, vienas AI kvietimas, timeout, anti-tamper); agentų promptai - ponas-obuolys bazė + Next.js/Supabase taisyklės iš CWK; `lang-reviewer` pašalintas (dubliavo `language-guard`).
**Paveikti puslapiai:** nėra (pakeista `.claude/`, `.po-config.json`, `CLAUDE.md`, `docs/AI-TOOLKIT.md`)
**Naujos įžvalgos:** Failo riba 300 LOC; wiki drift commit'ų nebeblokuoja, tik įspėja (`wiki_gate.block_commit_on_drift=false`); CWK Stop `prompt` hook'as pašalintas, nes įsiterpdavo į guard'o `claude --print` sesiją ir sugadindavo verdiktą.
