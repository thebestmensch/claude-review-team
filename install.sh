#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

green() { printf '\033[32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[33m%s\033[0m\n' "$1"; }
red() { printf '\033[31m%s\033[0m\n' "$1"; }

if [[ ! -d "$CLAUDE_DIR" ]]; then
    red "~/.claude not found. Is Claude Code installed?"
    exit 1
fi

mkdir -p "$CLAUDE_DIR/commands" "$CLAUDE_DIR/rules" "$CLAUDE_DIR/agents"

FORCE=0
for arg in "$@"; do
    [[ "$arg" == "--force" ]] && FORCE=1
done

installed=0
skipped=0

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
echo ""

echo "Skills:"
for f in "$SCRIPT_DIR"/commands/*.md; do
    install_file "$f" "$CLAUDE_DIR/commands/$(basename "$f")" "$(basename "$f")"
done

echo ""
echo "Dispatch rules:"
for f in "$SCRIPT_DIR"/rules/*.md; do
    install_file "$f" "$CLAUDE_DIR/rules/$(basename "$f")" "$(basename "$f")"
done

echo ""
echo "Agents:"
for f in "$SCRIPT_DIR"/agents/*.md; do
    install_file "$f" "$CLAUDE_DIR/agents/$(basename "$f")" "$(basename "$f")"
done

echo ""
echo "---"
printf "Installed: %d   Skipped: %d\n" "$installed" "$skipped"
echo ""

if [[ $skipped -gt 0 ]]; then
    echo "Some files skipped. Run with --force to overwrite."
    echo ""
fi

echo "Next: in your project, run /setup-ensemble to generate project configs."
echo "Or copy templates manually from: $SCRIPT_DIR/templates/"
echo ""
