#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

if [[ -z "${GODOT_BIN:-}" ]]; then
  echo "Set GODOT_BIN to the pinned Godot 4.7.2 binary." >&2
  exit 2
fi
if [[ ! -x "$GODOT_BIN" ]]; then
  echo "GODOT_BIN is not executable: $GODOT_BIN" >&2
  exit 2
fi
if [[ ! -f project.godot ]]; then
  echo "Godot project scaffold is not present yet; this repository currently contains the design and setup plan." >&2
  exit 2
fi

"$GODOT_BIN" --headless --path . --import
"$GODOT_BIN" --headless --path . --check-only --script res://scripts/prototype.gd
"$GODOT_BIN" --headless --path . --check-only --script res://scripts/paper_frame.gd
if command -v gdlint >/dev/null 2>&1; then
  gdlint .
fi
if [[ -d tests ]]; then
  while IFS= read -r test_file; do
    "$GODOT_BIN" --headless --path . --script "res://${test_file#./}"
  done < <(find tests -type f -name '*.gd' -print | sort)
fi
if grep -q 'name="Web"' export_presets.cfg 2>/dev/null; then
  "$GODOT_BIN" --headless --path . --export-release "Web" build/web/index.html
fi
