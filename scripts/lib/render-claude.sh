#!/usr/bin/env bash
# Adaptive CLAUDE.md starter block rendering.
# Source'inkite iš setup.sh: source "$STARTER_ROOT/scripts/lib/render-claude.sh"
#
# Reikalauja: detect_project + configure_project_auto jau iškviesti
# (PROJECT_LANG, PROJECT_FRAMEWORK, BUILD_CMD, LINT_CMD, TEST_CMD nustatyti).
#
# Funkcijos:
#   detect_target_state(target_dir)        — užpildo TARGET_HAS_*, TARGET_PKG_MGR, TARGET_E2E_CMD
#   render_starter_claude_block(target_dir, out_file) — renderiuoja adaptyvų bloką į out_file

# Aptinka, ką target jau turi savo CLAUDE.md ir lock failuose.
# SVARBU: prieš grep'inant content'ą, išfiltruojama tarp starter marker'ių esanti
# dalis — antraip detect skaitytų savo paties bloką ir per re-runs flip-flop'intų
# (Karpathy aptiktas → render skip → block be Karpathy → kitam run aptinka → įdeda atgal).
detect_target_state() {
  local target="$1" content=""
  TARGET_HAS_KARPATHY=0
  TARGET_HAS_CWK=0
  TARGET_PKG_MGR=""
  TARGET_E2E_CMD=""

  if [ -f "$target/CLAUDE.md" ]; then
    content=$(awk '
      /<!-- >>> STARTER \(advanced-vibe-coding-starter\) >>> -->/ { skip=1; next }
      /<!-- <<< STARTER \(advanced-vibe-coding-starter\) <<< -->/ { skip=0; next }
      !skip { print }
    ' "$target/CLAUDE.md")
    printf '%s' "$content" | grep -qiE 'karpathy|think before coding|surgical changes|goal-driven execution' \
      && TARGET_HAS_KARPATHY=1
    printf '%s' "$content" | grep -qE '<!-- CWK:|/create-prd|/generate-tasks|Claude Workflow Kit' \
      && TARGET_HAS_CWK=1
  fi
  # NEnaudojame .claude/commands/create-prd.md egzistencijos kaip CWK signalo —
  # mes patys jį įdiegiame per cwk_substitute_templates, todėl po pirmo run'o jis
  # visada egzistuotų ir CWK detect'as flip-flop'intų tarp run'ų.

  if [ -f "$target/pnpm-lock.yaml" ];           then TARGET_PKG_MGR="pnpm"
  elif [ -f "$target/bun.lockb" ] || [ -f "$target/bun.lock" ]; then TARGET_PKG_MGR="bun"
  elif [ -f "$target/yarn.lock" ];              then TARGET_PKG_MGR="yarn"
  elif [ -f "$target/package-lock.json" ];      then TARGET_PKG_MGR="npm"
  fi

  if [ -f "$target/package.json" ] && command -v jq >/dev/null 2>&1; then
    local has_e2e
    has_e2e=$(jq -r '.scripts["test:e2e"] // empty' "$target/package.json" 2>/dev/null)
    if [ -n "$has_e2e" ]; then
      TARGET_E2E_CMD="$(_pkg_run_cmd "test:e2e")"
    fi
  fi
}

# Verčia "npm run X" → "pnpm X" / "bun X" / "yarn X" pagal aptiktą TARGET_PKG_MGR.
# npm lieka "npm run X" (jo CLI to reikalauja).
_pkg_translate() {
  local cmd="$1"
  local pm="${TARGET_PKG_MGR:-npm}"
  case "$pm" in
    pnpm|bun|yarn) printf '%s' "$cmd" | sed -E "s/^npm run /$pm /; s/ npm run / $pm /g" ;;
    *)             printf '%s' "$cmd" ;;
  esac
}

# Sukonstruoja "$pm run|<empty> <script>" pagal pkg manager.
_pkg_run_cmd() {
  local script="$1"
  local pm="${TARGET_PKG_MGR:-npm}"
  case "$pm" in
    npm)        printf 'npm run %s' "$script" ;;
    pnpm|bun|yarn) printf '%s %s' "$pm" "$script" ;;
    *)          printf 'npm run %s' "$script" ;;
  esac
}

# Renderiuoja adaptyvų starter bloką. Sekcijos pridedamos sąlygiškai.
render_starter_claude_block() {
  local target="$1" out="$2"
  local build_c lint_c test_c agents
  build_c=$(_pkg_translate "$BUILD_CMD")
  lint_c=$(_pkg_translate "$LINT_CMD")
  test_c=$(_pkg_translate "$TEST_CMD")
  agents=$(ls "$target/.claude/agents/" 2>/dev/null | sed 's|\.md$||' | tr '\n' ',' | sed 's|,$||;s|,|, |g')

  {
    cat <<EOF
# Starter integracija (advanced-vibe-coding-starter)

Šis blokas autogeneruotas \`scripts/setup.sh\` pagal aptiktą projekto stack'ą.
Re-run perrašys TIK šį bloką tarp marker'ių; turinys virš/po marker'ių nepaliečiamas.

## Stack (auto-detected)
- Kalba/framework: \`${PROJECT_LANG:-?}${PROJECT_FRAMEWORK:+ / $PROJECT_FRAMEWORK}\`
- Duomenų bazė: \`${PROJECT_DB:-(nėra)}\`
- Hosting: \`${PROJECT_HOSTING:-(nėra)}\`
- Test framework: \`${PROJECT_TEST:-(nėra)}\`
- Package manager: \`${TARGET_PKG_MGR:-npm}\`

## Komandos (naudokite šias)
- Build: \`${build_c}\`
- Lint:  \`${lint_c}\`
- Test:  \`${test_c}\`
EOF
    [ -n "$TARGET_E2E_CMD" ] && printf -- "- E2E:   \`%s\`\n" "$TARGET_E2E_CMD"

    if [ "$TARGET_HAS_KARPATHY" = "1" ]; then
      printf '\n## Karpathy principai\n\nJau aprašyti šio CLAUDE.md viršuje (target turi savą versiją — neperrašoma).\n'
    else
      cat <<'EOF'

## Karpathy principai (LLM klaidų antidotas)

1. **Think Before Coding** — deklaruok prielaidas. Dvi interpretacijos → pateik abi. Nesupranti → klausk.
2. **Simplicity First** — minimalus kodas. Jokio error handling'o neįmanomiems scenarijams. 200 eil. → 50 → perrašai.
3. **Surgical Changes** — lieti tik tai, ko reikia. Tavo pakeitimai sukūrė orfanų — pašalink TIK savuosius.
4. **Goal-Driven Execution** — kiekviena užduotis: verifikuojamas tikslas. "Pridėk validaciją" → "Parašyk testus, tada juos pravertinkim".
EOF
    fi

    cat <<'EOF'

## Memoriki wiki protokolas

- Šaltiniai → `raw/` → `mempalace mine .` indeksuoja
- AI iš `wiki/index.md` randa relevant puslapius, atsako su citation'ais (`[[wiki/entities/...]]`)
- Sesijos pabaigoje: `mempalace mine .` + `wiki/log.md` įrašas
- Wiki frontmatter privalomas: `type`, `created`, `updated`, `sources`
EOF

    cat <<EOF

## Guard agentai (\`.claude/agents/\`)

Pre-commit hook iškviečia juos automatiškai. Bent vienas \`BLOCKED\` → commit sustabdytas.

Aktyvūs: ${agents:-(nė vienas neaptiktas)}
EOF

    cat <<'EOF'

## MCP serveriai

- Konfigūracija: `.mcp.json` (chmod 600, .gitignore'e — tokenai liktų lokaliai)
- Pavyzdys: `.mcp.json.example` · Suggested pagal stack: `.mcp.json.suggested`
- Re-run interaktyviai: `bash scripts/setup.sh` (be argumento, target dir'e)

## Verifikacija prieš commit'ą

```bash
EOF
    printf '%s\n' "$build_c"
    printf '%s\n' "$lint_c"
    printf '%s\n' "$test_c"
    [ -n "$TARGET_E2E_CMD" ] && printf '%s\n' "$TARGET_E2E_CMD"
    cat <<'EOF'
.claude/hooks/pre-commit.sh
```

## Kada kreiptis į naudotoją

- Yra dvi interpretacijos — pateik abi, nepasirink tyliai
- Tektų liesti 10+ failų ne scope'e (Surgical Changes pažeidimas)
- Reikalavimas prieštarauja production duomenims (pvz., destruktyvi migracija)
EOF

    if [ "$TARGET_HAS_CWK" = "1" ]; then
      printf '\n## CWK Workflow\n\nTarget turi savo CWK setup (aptikta). Starter neatkartoja konfigūracijos čia.\n'
    fi
  } > "$out"
}
