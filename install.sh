#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "$0")/src" && pwd)"
DST="${1:-.}"

confirm() { read -rp "  $1 already exists. Overwrite? [y/N] " yn; [[ "$yn" =~ ^[yY] ]]; }

copy_file() {
  local src="$1" dest="$2" label="$3"
  if [ -e "$dest" ] && ! confirm "$label"; then
    echo "    — skipped"
  else
    cp "$src" "$dest"
    echo "  ✓ $label"
  fi
}

copy_dir() {
  local src="$1" dest="$2" label="$3"
  if [ -d "$dest" ] && ! confirm "$label"; then
    echo "    — skipped"
  else
    mkdir -p "$dest"
    cp -r "$src"/* "$dest/"
    echo "  ✓ $label"
  fi
}

make_link() {
  local target="$1" link="$2" label="$3"
  if [ -L "$link" ]; then
    echo "  — $label (already linked)"
  else
    ln -s "$target" "$link"
    echo "  ✓ $label"
  fi
}

append_or_copy() {
  local src="$1" dest="$2"
  if [ -f "$dest" ]; then
    if confirm "AGENTS.md"; then
      printf "\n" >> "$dest"
      cat "$src" >> "$dest"
      echo "  ✓ appended"
    else
      echo "    — skipped"
    fi
  else
    cp "$src" "$dest"
    echo "  ✓ AGENTS.md"
  fi
}

main() {
  echo "🤌 let-em-cook — installing into $DST"

  mkdir -p "$DST/.agents/rules" "$DST/.agents/skills" "$DST/.claude"

  echo ""
  echo "Rules:"
  for f in "$SRC/.agents/rules/"*.md; do
    copy_file "$f" "$DST/.agents/rules/$(basename "$f")" ".agents/rules/$(basename "$f")"
  done

  echo ""
  echo "Skills:"
  for d in "$SRC/.agents/skills/"*/; do
    name="$(basename "$d")"
    copy_dir "$d" "$DST/.agents/skills/$name" ".agents/skills/$name/"
  done

  echo ""
  echo "Config:"
  append_or_copy "$SRC/AGENTS.md" "$DST/AGENTS.md"
  make_link AGENTS.md "$DST/CLAUDE.md" "CLAUDE.md → AGENTS.md"
  make_link ../.agents/rules "$DST/.claude/rules" ".claude/rules → .agents/rules"
  make_link ../.agents/skills "$DST/.claude/skills" ".claude/skills → .agents/skills"

  echo ""
  echo "Done. Let 'em cook. 🔥"
}

main
