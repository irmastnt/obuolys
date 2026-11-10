#!/usr/bin/env bash
# hooks/context-budget.sh
# ============================================================================
# UserPromptSubmit hook - matuoja tikrą konteksto užimtumą ir vieną kartą per
# slenkstį (default 40 % ir 60 %) įterpia trumpą įspėjimą.
# ----------------------------------------------------------------------------
# FAIL-OPEN, ne fail-closed (priešingai nei guard gate'ai): nieko neblokuoja,
# nedaro atskiro AI kvietimo, tinklo nenaudoja ir VISADA baigia darbą exit 0. Įspėjimų
# sistema, kuri sugeba sugadinti sesiją, yra blogesnė už jos nebuvimą.
#
# Claude užimtumas imamas iš paskutinio įrašo su message.usage:
#   input_tokens + cache_read_input_tokens + cache_creation_input_tokens.
# Codex rollout'e imamas paskutinis token_count įrašas:
#   last_token_usage.input_tokens / model_context_window.
# Codex cached_input_tokens yra input_tokens poaibis, todėl jo nepridedame.
#
# Skaitomas tik failo galas (400 KB), tad pirma eilutė būna nukirsta per vidurį.
# Todėl kiekviena eilutė parsinama atskirai per `fromjson? // empty`: sugadinta
# eilutė tyliai praleidžiama, o visos galiojančios (net jei failas turi tik
# vieną) lieka. Naivus jq per visą srautą tokiu atveju metė parse klaidą ir
# grąžindavo tuščią rezultatą be jokio matomo signalo.
# ============================================================================

set -uo pipefail

# jq patikra PIRMA - be jos hook'as nieko nedaro, tad neleidžiam sau nė vieno
# išorinio kvietimo (testas tikrina tylų exit 0 su tuščiu PATH).
command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat 2>/dev/null || true)
[ -n "$INPUT" ] || exit 0

TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
AGENT_ID=$(printf '%s' "$INPUT" | jq -r '.agent_id // empty' 2>/dev/null)
[ -n "$TRANSCRIPT" ] && [ -r "$TRANSCRIPT" ] || exit 0
[ -n "$SESSION_ID" ] || SESSION_ID="unknown"
[ -z "$AGENT_ID" ] || exit 0

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
[ -n "$REPO_ROOT" ] && cd "$REPO_ROOT" 2>/dev/null

# Konfigūracija skaitoma jq tiesiogiai (kaip Stop hook'uose), ne per po-config.sh -
# hook'as sukasi prieš KIEKVIENĄ vartotojo žinutę, tad turi likti lengvas.
ENABLED="true"
WINDOW_CFG="auto"
THRESHOLDS="40 60"
if [ -f ".po-config.json" ]; then
  # DĖMESIO: `// empty` boolean false paverstų tuštuma (jq `//` gaudo ir false, ir null),
  # tad opt-out tyliai nustotų veikti. Todėl false tikrinamas atskiru palyginimu.
  _e=$(jq -r 'if .context_gate.enabled == false then "false" else "true" end' .po-config.json 2>/dev/null)
  [ "$_e" = "false" ] && exit 0
  _w=$(jq -r '.context_gate.window_tokens // empty' .po-config.json 2>/dev/null)
  case "$_w" in ''|*[!0-9]*) : ;; *) WINDOW_CFG="$_w" ;; esac
  _t=$(jq -r '[.context_gate.warn_thresholds[]? | select(type == "number")] | map(tostring) | join(" ")' .po-config.json 2>/dev/null)
  case "$_t" in ''|*[!0-9\ ]*) : ;; *) THRESHOLDS="$_t" ;; esac
fi

# Paskutinis atpažintas pagrindinės sesijos usage įrašas. Transcript formatas
# pats nustato runtime, todėl hook'as lieka saugus net jei host'as perduoda
# neteisingą ar visai neperduoda PO_RUNTIME.
USAGE=$(tail -c 400000 "$TRANSCRIPT" 2>/dev/null | jq -Rr -n '
  [ inputs
    | fromjson? // empty
    | select(type == "object")
    | if (.type == "event_msg"
          and .payload.type == "token_count"
          and .payload.info.last_token_usage.input_tokens != null
          and .payload.info.model_context_window != null) then
        { runtime: "codex",
          used: .payload.info.last_token_usage.input_tokens,
          window: .payload.info.model_context_window,
          model: "" }
      elif (((.isSidechain // false) | not) and .message.usage != null) then
        { runtime: "claude",
          used: ((.message.usage.input_tokens // 0)
            + (.message.usage.cache_read_input_tokens // 0)
            + (.message.usage.cache_creation_input_tokens // 0)),
          window: 0,
          model: (.message.model // "") }
      else empty end
  ] | last
  | if . == null then empty else
      [.runtime, (.used | tostring), (.window | tostring), .model] | @tsv
    end' 2>/dev/null)
[ -n "$USAGE" ] || exit 0

IFS=$'\t' read -r DETECTED_RUNTIME USED DETECTED_WINDOW MODEL <<< "$USAGE"
case "$USED" in ''|*[!0-9]*) exit 0 ;; esac

# Codex pats įrašo faktinį langą. Claude lange taikomas modelio lookup:
# dabartinėms kartoms milijonas yra numatytoji reikšmė, Haiku - 200 tūkst.
case "$DETECTED_RUNTIME" in
  codex) WINDOW="$DETECTED_WINDOW" ;;
  claude)
    case "$MODEL" in
      claude-haiku-4-5*) WINDOW=200000 ;;
      *)                 WINDOW=1000000 ;;
    esac
    ;;
  *) exit 0 ;;
esac
[ "$WINDOW_CFG" = "auto" ] || WINDOW="$WINDOW_CFG"
[ "$WINDOW" -gt 0 ] 2>/dev/null || exit 0

PCT=$((USED * 100 / WINDOW))

# Per-sesiją būsena: kiekvienas slenkstis skelbiamas vieną kartą. Kitas
# session_id skaitiklį atstato savaime, tad /clear ir naujos sesijos veikia
# be atskiros logikos.
if [ "$DETECTED_RUNTIME" = "codex" ]; then
  MARKER_FILE=".codex/.po-context-notified"
else
  MARKER_FILE=".claude/.po-context-notified"
fi
LAST_LEVEL=0
if [ -f "$MARKER_FILE" ]; then
  _m=$(cat "$MARKER_FILE" 2>/dev/null)
  case "$_m" in
    "$SESSION_ID":*)
      _lvl=${_m#*:}
      case "$_lvl" in ''|*[!0-9]*) : ;; *) LAST_LEVEL="$_lvl" ;; esac
      ;;
  esac
fi

# Peršoktas aukščiausias dar nepaskelbtas slenkstis (šuolis nuo 30 % iki 65 %
# rodo tik 60 % pranešimą, o ne abu).
LEVEL=0
LEVEL_IDX=-1
_i=0
for _t in $THRESHOLDS; do
  if [ "$PCT" -ge "$_t" ] && [ "$_t" -gt "$LAST_LEVEL" ]; then
    LEVEL="$_t"
    LEVEL_IDX="$_i"
  fi
  _i=$((_i + 1))
done
[ "$LEVEL" -gt 0 ] || exit 0

mkdir -p "$(dirname "$MARKER_FILE")" 2>/dev/null || exit 0
printf '%s:%s\n' "$SESSION_ID" "$LEVEL" > "$MARKER_FILE" 2>/dev/null || exit 0

# Skaičiai tūkstančiais arba milijonais, kad eilutė liktų trumpa.
fmt_tokens() {
  if [ "$1" -ge 1000000 ]; then
    if [ $(( ($1 % 1000000) / 100000 )) -eq 0 ]; then
      printf '%d mln.' $(($1 / 1000000))
    else
      printf '%d,%d mln.' $(($1 / 1000000)) $(( ($1 % 1000000) / 100000 ))
    fi
  else
    printf '%d tūkst.' $(($1 / 1000))
  fi
}

USED_H=$(fmt_tokens "$USED")
WINDOW_H=$(fmt_tokens "$WINDOW")

if [ "$LEVEL_IDX" -eq 0 ]; then
  printf 'Kontekstas: %d %% (%s iš %s tokenų). Nuo šios ribos atsakymų tikslumas ima kristi, o kiekvienas kitas ėjimas apmokestina visą pokalbį iš naujo. Jei dabartinė užduotis baigta, dabar geras momentas `/clear`.\n' \
    "$PCT" "$USED_H" "$WINDOW_H"
else
  if [ "$DETECTED_RUNTIME" = "codex" ]; then
    WIKI_COMMAND='`$po-wiki-update`'
  else
    WIKI_COMMAND='`/po-wiki-update`'
  fi
  printf 'Kontekstas: %d %% (%s iš %s tokenų). Užbaik dabartinę mintį ir padaryk švarią pertrauką: %s perkelia tai, ką išsiaiškinom, į wiki failus, tada `/clear` pradeda švariai. Auto-compact laukti neverta: jis suspaus pokalbį pats, o ką tiksliai praras, tu nekontroliuoji.\n' \
    "$PCT" "$USED_H" "$WINDOW_H" "$WIKI_COMMAND"
fi

exit 0
