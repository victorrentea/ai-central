#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
REPOS_FILE="$SKILLS_DIR/user-repos-using.txt"
TEMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TEMP_DIR"; }
trap cleanup EXIT

found_any=false

while IFS= read -r url; do
  [[ -z "$url" || "$url" == "#"* ]] && continue

  repo_name=$(basename "$url" .git)
  clone_dir="$TEMP_DIR/$repo_name"

  echo "Scanning $url..." >&2
  git clone --depth=1 --quiet "$url" "$clone_dir" 2>/dev/null || {
    echo "Failed to clone $url" >&2
    continue
  }

  for skill_dir in "$SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    ext_name="${skill_name}-extension"

    for search_dir in ".agents/skills" ".github/skills" ".claude/skills"; do
      ext_skill="$clone_dir/$search_dir/$ext_name/SKILL.md"
      if [[ -f "$ext_skill" ]]; then
        found_any=true
        echo "### $ext_name (from $repo_name)"
        echo ""
        cat "$ext_skill"
        echo ""
      fi
    done
  done

done < "$REPOS_FILE"

if ! $found_any; then
  echo "No extension skills found."
fi
