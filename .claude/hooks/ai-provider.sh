#!/usr/bin/env bash
# Bendras Claude Code / Codex AI guard vykdymo adapteris (Bash 3.2 suderinamas).

_PO_AI_PROVIDER_DIR=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)

# Vykdo komandą su promptu per stdin ir laiko riba. Portable watchdog reikalingas
# macOS, kur `timeout` standartiškai neįdiegtas.
_po_run_timed() {
  _prt_to="$1"; _prt_prompt="$2"; _prt_stdout="$3"; shift 3
  if command -v timeout >/dev/null 2>&1; then
    timeout "$_prt_to" "$@" < "$_prt_prompt" > "$_prt_stdout" 2>/dev/null
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$_prt_to" "$@" < "$_prt_prompt" > "$_prt_stdout" 2>/dev/null
  else
    "$@" < "$_prt_prompt" > "$_prt_stdout" 2>/dev/null &
    _prt_pid=$!
    ( sleep "$_prt_to"; kill -TERM "$_prt_pid" 2>/dev/null; sleep 1; kill -KILL "$_prt_pid" 2>/dev/null ) >/dev/null 2>&1 &
    _prt_watchdog=$!
    wait "$_prt_pid" 2>/dev/null; _prt_rc=$?
    pkill -P "$_prt_watchdog" 2>/dev/null
    kill -TERM "$_prt_watchdog" 2>/dev/null
    wait "$_prt_watchdog" 2>/dev/null
    return "$_prt_rc"
  fi
}

# Aiškiai pasirinktas provideris niekada tyliai neperjungiamas į kitą. `auto`
# pirmiausia gerbia runtime, tada renkasi Codex, po to Claude.
po_resolve_guard_provider() {
  _prgp_requested="${1:-${PO_GUARD_PROVIDER:-auto}}"
  case "$_prgp_requested" in
    claude|codex)
      command -v "$_prgp_requested" >/dev/null 2>&1 || return 69
      printf '%s' "$_prgp_requested"
      return 0 ;;
    auto|'') : ;;
    *) return 64 ;;
  esac

  case "${PO_RUNTIME:-}" in
    codex|claude)
      if command -v "$PO_RUNTIME" >/dev/null 2>&1; then
        printf '%s' "$PO_RUNTIME"
        return 0
      fi ;;
  esac
  if command -v codex >/dev/null 2>&1; then
    printf '%s' codex
  elif command -v claude >/dev/null 2>&1; then
    printf '%s' claude
  else
    return 69
  fi
}

# Numatytasis guard timeout (sek.) pagal providerį. `codex exec` kaskart kelia app-server ir
# mąsto ilgiau nei `claude --print`, todėl bendras 120s jam nukirsdavo TEISĖTĄ darbą ir žymėdavo
# fail-closed BLOCKED. Claude kelias lieka trumpas sąmoningai: jis yra numatytasis (PO_RUNTIME=claude
# -> auto), tad pakibimo atveju commit'as atblokuojamas per 2 min, ne per 10.
po_guard_timeout_default() {
  case "${1:-}" in
    codex) printf '600' ;;
    *)     printf '120' ;;
  esac
}

po_guard_schema_path() {
  for _pgsp_path in \
    "${PO_GUARD_SCHEMA:-}" \
    "${PLUGIN_ROOT:-}/codex/schemas/guard-verdict.schema.json" \
    "${CLAUDE_PLUGIN_ROOT:-}/codex/schemas/guard-verdict.schema.json" \
    "${_PO_AI_PROVIDER_DIR:-}/../codex/schemas/guard-verdict.schema.json" \
    ".codex/schemas/guard-verdict.schema.json" \
    ".claude/schemas/guard-verdict.schema.json"; do
    { [ -n "$_pgsp_path" ] && [ "$_pgsp_path" != "/codex/schemas/guard-verdict.schema.json" ] \
      && [ -f "$_pgsp_path" ]; } || continue
    # ANTI-DOWNGRADE: repo-versionuojama schema, staged'inama ŠIAME commit'e, imama iš HEAD
    # (kaip guard promptai pre-commit.sh) - staged schemos pakeitimas negali paveikti savo
    # paties commit'o vertinimo. Laikiną HEAD kopiją išvalo _po_guard_schema_cleanup.
    case "$_pgsp_path" in
      .codex/schemas/*|.claude/schemas/*)
        if git diff --cached --name-only 2>/dev/null | grep -qxF "$_pgsp_path"; then
          _pgsp_tmp=$(mktemp -t po-guard-schema.XXXXXX) || return 1
          if git show "HEAD:$_pgsp_path" > "$_pgsp_tmp" 2>/dev/null && [ -s "$_pgsp_tmp" ]; then
            printf '%s' "$_pgsp_tmp"
            return 0
          fi
          # HEAD versijos nėra (schema nauja šiame commit'e) - kandidatas nepatikimas.
          rm -f "$_pgsp_tmp"
          continue
        fi ;;
    esac
    printf '%s' "$_pgsp_path"
    return 0
  done
  return 1
}

# Išvalo po_guard_schema_path sukurtą laikiną HEAD kopiją. Atpažįsta tik mktemp
# šablono kelius, todėl repo ar plugin schemos failų niekada neliečia.
_po_guard_schema_cleanup() {
  case "${1:-}" in */po-guard-schema.*) rm -f "$1" ;; esac
}

po_run_claude() {
  _prc_to="$1"; _prc_prompt="$2"; _prc_out="$3"; _prc_model="${4:-}"
  command -v claude >/dev/null 2>&1 || return 69
  if [ -n "$_prc_model" ]; then
    _po_run_timed "$_prc_to" "$_prc_prompt" "$_prc_out" claude --print --model "$_prc_model"
  else
    _po_run_timed "$_prc_to" "$_prc_prompt" "$_prc_out" claude --print
  fi
}

po_run_codex() {
  _prx_to="$1"; _prx_prompt="$2"; _prx_out="$3"; _prx_model="${4:-}"
  command -v codex >/dev/null 2>&1 || return 69
  command -v jq >/dev/null 2>&1 || return 69
  _prx_schema=$(po_guard_schema_path) || return 66
  _prx_last=$(mktemp -t po-codex-last.XXXXXX) || { _po_guard_schema_cleanup "$_prx_schema"; return 70; }
  _prx_stdout=$(mktemp -t po-codex-stdout.XXXXXX) || { rm -f "$_prx_last"; _po_guard_schema_cleanup "$_prx_schema"; return 70; }
  : > "$_prx_out"

  set -- codex exec --ephemeral --sandbox read-only \
    -c features.hooks=false \
    --output-schema "$_prx_schema" \
    --output-last-message "$_prx_last"
  [ -n "$_prx_model" ] && set -- "$@" --model "$_prx_model"
  set -- "$@" -
  if ! _po_run_timed "$_prx_to" "$_prx_prompt" "$_prx_stdout" "$@"; then
    rm -f "$_prx_last" "$_prx_stdout"
    _po_guard_schema_cleanup "$_prx_schema"
    return 1
  fi

  if ! jq -e '
      type == "object"
      and ((keys | sort) == ["summary", "verdict"])
      and (.verdict == "OK" or .verdict == "WARN" or .verdict == "BLOCKED")
      and ((.summary | type) == "string")
      and ((.summary | length) > 0)
    ' "$_prx_last" >/dev/null 2>&1; then
    rm -f "$_prx_last" "$_prx_stdout"
    _po_guard_schema_cleanup "$_prx_schema"
    return 65
  fi
  _prx_verdict=$(jq -r '.verdict' "$_prx_last")
  _prx_summary=$(jq -r '.summary' "$_prx_last")
  printf 'VERDICT: %s\n%s\n' "$_prx_verdict" "$_prx_summary" > "$_prx_out"
  rm -f "$_prx_last" "$_prx_stdout"
  _po_guard_schema_cleanup "$_prx_schema"
}

# $1=provider (claude|codex|auto), $2=timeout, $3=prompt, $4=output, $5=model.
po_run_guard_model() {
  _prgm_provider=$(po_resolve_guard_provider "$1") || return $?
  case "$_prgm_provider" in
    claude) po_run_claude "$2" "$3" "$4" "${5:-}" ;;
    codex)  po_run_codex "$2" "$3" "$4" "${5:-}" ;;
    *) return 64 ;;
  esac
}
