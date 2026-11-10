#!/usr/bin/env bash
# Bendras Claude Code ir Codex hook įvesties normalizatorius.
# Šis failas source'inamas; shell options nekeičia.

po_hook_command() {
  command -v jq >/dev/null 2>&1 || return 1
  printf '%s' "$1" | jq -rj '.tool_input.command // empty' 2>/dev/null
}

po_hook_changed_paths() {
  command -v jq >/dev/null 2>&1 || return 1
  _po_hi_json="$1"
  _po_hi_direct=$(printf '%s' "$_po_hi_json" | jq -rj '.tool_input.file_path // empty' 2>/dev/null) || return 1
  _po_hi_command=$(printf '%s' "$_po_hi_json" | jq -rj '.tool_input.command // empty' 2>/dev/null) || return 1

  {
    if [ -n "$_po_hi_direct" ]; then
      case "$_po_hi_direct" in
        *$'\n'*|*$'\r'*|*$'\t'*) : ;;
        *) printf '%s\n' "$_po_hi_direct" ;;
      esac
    fi
    printf '%s\n' "$_po_hi_command" \
      | sed -nE 's/^\*\*\* (Add|Update|Delete) File: (.*)$/\2/p' \
      | while IFS= read -r _po_hi_path; do
          case "$_po_hi_path" in
            ''|*$'\r'*|*$'\t'*) continue ;;
            *) printf '%s\n' "$_po_hi_path" ;;
          esac
        done
  } | awk 'length($0) && !seen[$0]++'
}
