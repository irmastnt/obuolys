#!/usr/bin/env bash
# Sinchronizuoja CWK versiją per visus failus, kuriuose ji minima.
# Skaitykite kaip "single source of truth helper'į".
#
# Naudojimas:
#   bash scripts/bump-version.sh 3.0.2
#
# Atnaujinami failai:
#   - scripts/setup.sh           CWK_VERSION="X.Y.Z"
#   - CLAUDE.md (antraštė + naujovės eilutė)
#   - README.md (antraštė + sekcijos antraštė)
#   - scripts/verify.sh (CWK pipeline antraštė + jq check)

set -euo pipefail

cd "$(dirname "$0")/.."

NEW="${1:-}"
if [ -z "$NEW" ] || ! echo "$NEW" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  echo "Naudojimas: bash scripts/bump-version.sh <X.Y.Z>" >&2
  echo "Pvz.: bash scripts/bump-version.sh 3.0.2" >&2
  exit 1
fi

OLD=$(grep -oE 'CWK_VERSION="[0-9]+\.[0-9]+\.[0-9]+"' scripts/setup.sh | head -1 | sed -E 's|CWK_VERSION="([^"]+)"|\1|')
if [ -z "$OLD" ]; then
  echo "ERR: dabartinė CWK_VERSION nerasta scripts/setup.sh" >&2
  exit 1
fi

if [ "$OLD" = "$NEW" ]; then
  echo "Versija jau yra $NEW, niekas nedaroma."
  exit 0
fi

echo "Bump: v$OLD → v$NEW"
echo ""

# In-place pakeitimai. macOS sed reikalauja .bak (ir kelio backup'ui).
sed_inplace() {
  local pattern="$1" file="$2"
  if [ ! -f "$file" ]; then
    echo "  (praleidžiama, nerastas: $file)"
    return
  fi
  sed -i.bak "$pattern" "$file"
  rm -f "${file}.bak"
  echo "  ✓ $file"
}

sed_inplace "s|CWK_VERSION=\"$OLD\"|CWK_VERSION=\"$NEW\"|g" scripts/setup.sh
sed_inplace "s|v$OLD|v$NEW|g" CLAUDE.md
sed_inplace "s|\\*\\*v$OLD naujovė|**v$NEW naujovė|g" CLAUDE.md
sed_inplace "s|v$OLD|v$NEW|g" README.md
sed_inplace "s|v$OLD|v$NEW|g" scripts/verify.sh
sed_inplace "s|test \"\\\$(jq -r .version .claude/.cwk-config.json 2>/dev/null)\" = $OLD|test \"\\\$(jq -r .version .claude/.cwk-config.json 2>/dev/null)\" = $NEW|g" scripts/verify.sh

echo ""
echo "Patvirtinkite: grep -rn '$OLD\\|$NEW' --include='*.sh' --include='*.md' . | head -10"
echo "Tada paleiskite setup.sh, kad regeneruotų .cwk-config.json:"
echo "  bash scripts/setup.sh"
