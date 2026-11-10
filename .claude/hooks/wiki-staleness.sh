#!/usr/bin/env bash
# hooks/wiki-staleness.sh
# ============================================================================
# Commit-time wiki gate. Grąžina exit 1, jei wiki/ atsilieka nuo kodo IR šis
# commit'as wiki neatnaujina. Perpanaudoja wiki-drift-stop.sh drift skaičiavimą,
# BET be marker rašymo ir be Stop JSON (skirta pre-commit kontekstui).
# ----------------------------------------------------------------------------
# Exit kodai:
#   0 = OK (nėra drift / wiki gate išjungtas / nėra wiki / commit atnaujina wiki)
#   1 = wiki drift - commit'as turi būti blokuojamas (santrauka į stdout)
# ============================================================================

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$REPO_ROOT" || exit 0

# --- Konfigūracija (PO_WIKI_GATE) ---
_po_find_hook_dir() {
  # TRUST: pirmenybė patikimam plugin'ui (${CLAUDE_PLUGIN_ROOT}), tada repo .claude/hooks (radinys OA).
  for d in "${CLAUDE_PLUGIN_ROOT:-}/hooks" ".claude/hooks" "$(dirname "${BASH_SOURCE[0]:-$0}")"; do
    if [ -n "$d" ] && [ "$d" != "/hooks" ] && [ -f "$d/po-config.sh" ]; then
      printf '%s' "$d"; return 0
    fi
  done
  printf '%s' "."
}
PO_HOOK_DIR=$(_po_find_hook_dir)
# Jei kvietėjas (pre-commit.sh) perdavė TRUSTED po-config.sh kelią per PO_CONFIG_SH (HEAD baseline,
# kai .claude/hooks staged - radinys VA), naudojam jį, ne galimai tampered worktree kopiją.
if [ -n "${PO_CONFIG_SH:-}" ] && [ -f "${PO_CONFIG_SH:-}" ]; then
  # shellcheck disable=SC1090
  . "$PO_CONFIG_SH"
elif [ -f "$PO_HOOK_DIR/po-config.sh" ]; then
  # shellcheck disable=SC1090
  . "$PO_HOOK_DIR/po-config.sh"
fi

# Wiki gate gali būti išjungtas per .po-config.json wiki_gate.block_commit_on_drift=false.
# ANTI-DOWNGRADE (radinys LA): jei `.po-config.json` keičiamas ŠIAME commit'e, neleidžiam jo išjungti
# čia - imam HEAD (trusted) reikšmę; išjungti galima TIK jei HEAD jau turėjo false. Kitaip silpnesnis
# policy galiotų būtent commit'ui, kuris jį įveda (self-bypass).
_po_wiki_gate="${PO_WIKI_GATE:-true}"
# Drift slenkstis: blokuojam tik kai efektyvus drift'as (istorija + šis commit'as) >= threshold.
# Tas pats ANTI-DOWNGRADE galioja ir slenksčiui: staged config negali jo pakelti savo commit'ui.
_po_wiki_threshold="${PO_WIKI_DRIFT_THRESHOLD:-3}"
if git diff --cached --name-only 2>/dev/null | grep -qxF '.po-config.json'; then
  if command -v jq >/dev/null 2>&1; then
    _head_wiki=$(git show HEAD:.po-config.json 2>/dev/null | jq -r '.wiki_gate.block_commit_on_drift' 2>/dev/null)
    case "$_head_wiki" in false) : ;; *) _po_wiki_gate="true" ;; esac
    _head_t=$(git show HEAD:.po-config.json 2>/dev/null | jq -r '.wiki_gate.drift_block_threshold // empty' 2>/dev/null)
    case "$_head_t" in ''|*[!0-9]*) _po_wiki_threshold=3 ;; *) _po_wiki_threshold="$_head_t" ;; esac
  else
    _po_wiki_gate="true"
    _po_wiki_threshold=3
  fi
fi
[ "$_po_wiki_gate" = "true" ] || exit 0
case "$_po_wiki_threshold" in ''|*[!0-9]*) _po_wiki_threshold=3 ;; esac

LOG_FILE="wiki/log.md"

# ANTI-TAMPER (radinys PA): staged wiki/log.md IŠTRYNIMAS/PERVADINIMAS ištrintų gate baseline ir
# išjungtų wiki drift kontrolę VISIEMS tolesniems commit'ams (be log.md `-f` patikra žemiau exit'intų
# 0). Todėl, kai gate įjungtas, tokį commit'ą blokuojam. (Tikrinam PRIEŠ `-f` - ištrintas worktree
# failas kitaip praslystų.)
_wlogstatus=$(git diff --cached --name-status -- "$LOG_FILE" 2>/dev/null | cut -f1)
case "$_wlogstatus" in
  D*|R*)
    echo "Wiki gate: šis commit'as trina/pervadina wiki/log.md - tai ištrintų gate baseline ir išjungtų wiki drift kontrolę tolesniems commit'ams."
    echo "Jei tikrai būtina - laikinai PO_WIKI_GATE=false arba --no-verify; kitaip palik wiki/log.md."
    exit 1 ;;
esac

[ -f "$LOG_FILE" ] || exit 0

# Jei šis commit'as PATS prideda REALŲ /po-wiki-update įrašą - leidžiam (baseline advancina;
# /po-wiki-update sintetina ir senus commit'us). Reikalaujam pridėtos DATUOTOS antraštės
# `## YYYY-MM-DD ...` IR bent DVIEJŲ struktūrinių body laukų su turiniu (`**Laukas:** tekstas`) -
# realus /po-wiki-update įrašas turi 4 (`Šaltinis`/`Veiksmas`/`Paveikti puslapiai`/`Naujos įžvalgos`),
# tad ≥2 atmeta trivialų vieno-lauko fake'ą (radinys OB), bet nepraleidžia realaus įrašo. Trivialli
# eilutė ('x'/whitespace), fake antraštė ('## noop') ar bare antraštė be body NEpraeina.
# (Kooperatyvus gate; semantinio turinio teisingumo - ar įrašas tikrai aprašo PAKEISTĄ kodą -
# negarantuojam: tai savidisciplinos riba, ją dengia vartotojo paleistas realus /po-wiki-update + AI
# guard'ai, ne sintaksinis gate. Legalūs opt-out'ai: PO_WIKI_GATE=false, --no-verify.)
if git diff --cached --name-only -- "$LOG_FILE" 2>/dev/null | grep -q .; then
  _wadded=$(git diff --cached -U0 -- "$LOG_FILE" 2>/dev/null | grep '^+' | grep -vE '^\+\+\+' | sed 's/^.//')
  _wfields=$(printf '%s\n' "$_wadded" | grep -cE '^\*\*[^*]+:\*\*[[:space:]]*[^[:space:]]')
  if printf '%s\n' "$_wadded" | grep -qE '^## [0-9]{4}-[0-9]{2}-[0-9]{2}' \
     && [ "${_wfields:-0}" -ge 2 ]; then
    exit 0
  fi
fi

# Efektyvus drift'as = akumuliuotas istorijoje + šis commit'as (jei jis stage'ina ne-wiki
# failus, o log.md NE staged - praėjom aukščiau esantį patikrinimą, tad jis PATS kuria drift'ą).
# Blokuojam tik kai efektyvus drift'as pasiekia slenkstį - tarpiniai commit'ai iki jo leidžiami
# (feature-level wiki sync strategija: /po-wiki-update kartą per feature, ne per kiekvieną commit'ą).
THIS_COMMIT_DRIFT=0
if git diff --cached --name-only -- . ':!wiki/' 2>/dev/null | grep -q .; then
  THIS_COMMIT_DRIFT=1
fi

COUNT=0
LAST_WIKI_COMMIT=$(git log -1 --format=%H -- "$LOG_FILE" 2>/dev/null)
if [ -n "$LAST_WIKI_COMMIT" ]; then
  # rev-list --count vietoj `wc -l` - veikia ir minimalioje PATH aplinkoje (pre-commit kontekstas).
  COUNT=$(git rev-list --count "${LAST_WIKI_COMMIT}..HEAD" -- . ':!wiki/' 2>/dev/null)
  case "$COUNT" in ''|*[!0-9]*) COUNT=0 ;; esac
fi

EFFECTIVE=$((COUNT + THIS_COMMIT_DRIFT))
[ "$EFFECTIVE" -gt 0 ] || exit 0
[ "$EFFECTIVE" -ge "$_po_wiki_threshold" ] || exit 0

echo "Wiki drift: $EFFECTIVE commit(ai) (įskaitant šį) palietė ne-wiki failus po paskutinio wiki/log.md atnaujinimo (blokavimo slenkstis: $_po_wiki_threshold)."
echo "Paleisk /po-wiki-update prieš commit'ą arba įtrauk wiki/ pakeitimus į šį commit'ą."
exit 1
