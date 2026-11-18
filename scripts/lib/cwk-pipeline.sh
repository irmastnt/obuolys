#!/usr/bin/env bash
# CWK 4 etapų pipeline konfigūracija.
# Source'inkite iš setup.sh: source "$(dirname "$0")/lib/cwk-pipeline.sh"
#
# Reikalauja: detect_project, configure_project_auto jau iškviesti.
# Prieinama: $CWK_VERSION, $BUILD_CMD, $LINT_CMD, $TEST_CMD, $UI_LANG,
#            $COVERAGE_THRESHOLD, $MAX_FILE_LINES, ir visi PROJECT_* kintamieji.
#
# Funkcijos: cwk_substitute_templates, cwk_write_config,
#            cwk_merge_stop_hook, cwk_generate_suggested_mcp.

cwk_substitute_templates() {
  local templates_dir=".claude/commands/_templates"
  local commands_dir=".claude/commands"
  if [ ! -d "$templates_dir" ]; then
    warn "$templates_dir nerastas. CWK pipeline komandos neįdiegiamos."
    return 1
  fi

  local count=0 tpl out
  for tpl in "$templates_dir"/*.md; do
    [ -f "$tpl" ] || continue
    out="$commands_dir/$(basename "$tpl")"
    sed \
      -e "s|{{BUILD_CMD}}|${BUILD_CMD}|g" \
      -e "s|{{LINT_CMD}}|${LINT_CMD}|g" \
      -e "s|{{TEST_CMD}}|${TEST_CMD}|g" \
      -e "s|{{COVERAGE_THRESHOLD}}|${COVERAGE_THRESHOLD}|g" \
      -e "s|{{MAX_FILE_LINES}}|${MAX_FILE_LINES}|g" \
      -e "s|{{UI_LANG}}|${UI_LANG}|g" \
      "$tpl" > "$out"
    count=$((count + 1))
  done
  ok "Sugeneruota $count CWK komandų į $commands_dir/"

  set +o pipefail
  local remaining
  remaining=$(grep -rE '\{\{[A-Z_]+\}\}' "$commands_dir" --exclude-dir=_templates 2>/dev/null || true)
  set -o pipefail
  if [ -n "$remaining" ]; then
    warn "Liko nesumažinti placeholderiai. Perinit'inkite po update'o:"
    echo "$remaining"
  fi
}

cwk_write_config() {
  if ! command -v jq >/dev/null 2>&1; then
    warn "jq nerastas. .cwk-config.json praleidžiamas. Įdiekite: brew install jq (macOS) arba apt install jq (Linux)."
    return 1
  fi

  jq -n \
    --arg version "$CWK_VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg lang "${PROJECT_LANG:-}" \
    --arg fw "${PROJECT_FRAMEWORK:-}" \
    --arg db "${PROJECT_DB:-}" \
    --arg pay "${PROJECT_PAYMENTS:-}" \
    --arg host "${PROJECT_HOSTING:-}" \
    --arg test "${PROJECT_TEST:-}" \
    --arg build "$BUILD_CMD" \
    --arg lint "$LINT_CMD" \
    --arg testcmd "$TEST_CMD" \
    --argjson cov "$COVERAGE_THRESHOLD" \
    --argjson maxl "$MAX_FILE_LINES" \
    --arg uil "$UI_LANG" \
    '{
      version: $version,
      installed_at: $ts,
      starter_identity: {
        memPalace: true, memoriki: true, karpathy_principles: 4,
        lt_guards: ["payment-guard","db-migration-guard","language-guard","file-size-guard","risk-assessor","security-guard","test-coverage-guard"]
      },
      project: { language: $lang, framework: $fw, database: $db, payments: $pay, hosting: $host, test_framework: $test },
      config: { coverage_threshold: $cov, max_file_lines: $maxl, build_cmd: $build, lint_cmd: $lint, test_cmd: $testcmd, ui_language: $uil }
    }' > .claude/.cwk-config.json
  ok ".cwk-config.json (v$CWK_VERSION) sukurtas"
}

cwk_merge_stop_hook() {
  if ! command -v jq >/dev/null 2>&1 || [ ! -f .claude/settings.json ]; then
    return 1
  fi

  local marker="CWK_STOP_HOOK_V1"
  local prompt="[${marker}] Prieš baigiant šią sesiją: jei buvo kodo pakeitimų, patvirtinkite, kad 1) Kompiliuoja (${BUILD_CMD}), 2) Testai praeina (${TEST_CMD}), 3) Be lint klaidų (${LINT_CMD}). Jei kuris žingsnis nebuvo paleistas, įspėkite vartotoją. Neblokuoti, tik priminti."
  local tmp
  tmp=$(mktemp)

  jq --arg prompt "$prompt" --arg marker "$marker" '
    .hooks = (.hooks // {}) |
    .hooks.Stop = (
      ((.hooks.Stop // []) | map(select(
        (.hooks // []) | map(.prompt // "") | any(contains($marker)) | not
      ))) +
      [{matcher: ".*", hooks: [{type: "prompt", prompt: $prompt, timeout: 10}]}]
    )
  ' .claude/settings.json > "$tmp" && mv "$tmp" .claude/settings.json
  ok "Stop hook'as atnaujintas .claude/settings.json (kiti dalyvio hook'ai išsaugoti)"
}

cwk_generate_suggested_mcp() {
  [ -f .mcp.json.example ] && command -v jq >/dev/null 2>&1 || return 0

  local keep_filter
  keep_filter=$(jq -n \
    --arg db "$PROJECT_DB" --arg pay "$PROJECT_PAYMENTS" \
    --arg host "$PROJECT_HOSTING" --arg test "$PROJECT_TEST" \
    '{
      supabase: ($db == "supabase"),
      stripe:   ($pay == "stripe"),
      vercel:   ($host == "vercel"),
      playwright: ($test == "playwright"),
      context7: true,
      "chrome-devtools": true
    }')
  jq --argjson keep "$keep_filter" \
    '.mcpServers = (.mcpServers | with_entries(select($keep[.key] == true)))' \
    .mcp.json.example > .mcp.json.suggested
  ok ".mcp.json.suggested sugeneruotas (filtruotas pagal stack'ą)"
}

# Orkestruoja visą CWK §5 bloką.
cwk_pipeline_setup() {
  cwk_substitute_templates
  cwk_write_config
  cwk_merge_stop_hook
  cwk_generate_suggested_mcp
}
