#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red() { printf '\033[31m%s\033[0m\n' "$1"; }
dim() { printf '\033[2m%s\033[0m\n' "$1"; }

if [[ ! -d "$CLAUDE_DIR" ]]; then
    red "~/.claude not found. Is Claude Code installed?"
    exit 1
fi

mkdir -p "$CLAUDE_DIR/commands" "$CLAUDE_DIR/rules" "$CLAUDE_DIR/agents"

FORCE=0
NO_FRONTEND=0
for arg in "$@"; do
    [[ "$arg" == "--force" ]] && FORCE=1
    [[ "$arg" == "--no-frontend" ]] && NO_FRONTEND=1
done

# Frontend-only files (skipped with --no-frontend)
FRONTEND_COMMANDS="visual-qa.md accessibility-qa.md tone-qa.md"
FRONTEND_RULES="visual-qa-during-ui-work.md"

installed=0
skipped=0
excluded=0

is_frontend_file() {
    local name="$1" list="$2"
    [[ " $list " == *" $name "* ]]
}

install_file() {
    local src="$1" dest="$2" name="$3"
    if [[ -f "$dest" ]] && [[ "$FORCE" != "1" ]]; then
        yellow "  skip  $name (exists, use --force to overwrite)"
        ((skipped++)) || true
        return
    fi
    cp "$src" "$dest"
    green "  add   $name"
    ((installed++)) || true
}

echo ""
echo "Review Ensemble"
echo "==============="
if [[ "$NO_FRONTEND" == "1" ]]; then
    dim "(backend only — skipping visual/accessibility/tone QA)"
fi
echo ""

echo "Skills:"
for f in "$SCRIPT_DIR"/commands/*.md; do
    name=$(basename "$f")
    if [[ "$NO_FRONTEND" == "1" ]] && is_frontend_file "$name" "$FRONTEND_COMMANDS"; then
        dim "    --  $name (frontend, skipped)"
        ((excluded++)) || true
        continue
    fi
    install_file "$f" "$CLAUDE_DIR/commands/$name" "$name"
done

echo ""
echo "Dispatch rules:"
for f in "$SCRIPT_DIR"/rules/*.md; do
    name=$(basename "$f")
    if [[ "$NO_FRONTEND" == "1" ]] && is_frontend_file "$name" "$FRONTEND_RULES"; then
        dim "    --  $name (frontend, skipped)"
        ((excluded++)) || true
        continue
    fi
    install_file "$f" "$CLAUDE_DIR/rules/$name" "$name"
done

echo ""
echo "Agents:"
for f in "$SCRIPT_DIR"/agents/*.md; do
    install_file "$f" "$CLAUDE_DIR/agents/$(basename "$f")" "$(basename "$f")"
done

echo ""
echo "---"
printf "Installed: %d   Skipped: %d" "$installed" "$skipped"
if [[ $excluded -gt 0 ]]; then
    printf "   Excluded: %d (frontend)" "$excluded"
fi
echo ""
echo ""

if [[ $skipped -gt 0 ]]; then
    echo "Some files skipped. Run with --force to overwrite."
    echo ""
fi

echo "Next: in your project, run /setup-ensemble to generate project configs."
echo "Or copy templates manually from: $SCRIPT_DIR/templates/"
echo ""
