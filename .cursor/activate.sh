#!/usr/bin/env bash
# Объединяет platform + project rules/skills в активные .cursor/rules и .cursor/skills
# Fitness-only: после копирования расширяет Nest-глобы src/** → backend/api/src/** (platform не трогаем).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
RULES_DIR="$ROOT/rules"
SKILLS_DIR="$ROOT/skills"

mkdir -p "$RULES_DIR"
rm -f "$RULES_DIR"/*.mdc
cp "$ROOT/platform/rules/"*.mdc "$RULES_DIR/"
if [ -d "$ROOT/project/rules" ] && [ -n "$(ls -A "$ROOT/project/rules"/*.mdc 2>/dev/null)" ]; then
  cp "$ROOT/project/rules/"*.mdc "$RULES_DIR/"
fi

# Monorepo path rewrite (active rules only; sources in platform/ stay portable)
python3 - "$RULES_DIR" <<'PY'
import re, sys
from pathlib import Path

rules_dir = Path(sys.argv[1])

def expand(body: str) -> str:
    parts = [p.strip() for p in body.split(",") if p.strip()]
    extra = []
    for p in parts:
        if p.startswith("backend/api"):
            continue
        if p.startswith("src/") or p == "src/**":
            mapped = "backend/api/" + p
            if mapped not in parts and mapped not in extra:
                extra.append(mapped)
        elif p.startswith("test/") or p == "test/**":
            mapped = "backend/api/" + p
            if mapped not in parts and mapped not in extra:
                extra.append(mapped)
        elif p.startswith("spec/") or p == "spec/**":
            mapped = "backend/api/" + p
            if mapped not in parts and mapped not in extra:
                extra.append(mapped)
    return ",".join(parts + extra)

for path in rules_dir.glob("*.mdc"):
    text = path.read_text()
    lines = text.splitlines(keepends=True)
    out = []
    changed = False
    for line in lines:
        m = re.match(r'(globs:\s*)("?)([^"\n]+)("?)(\s*)$', line)
        if not m:
            out.append(line)
            continue
        prefix, q1, body, q2, trail = m.groups()
        # keep quote style if either side quoted
        quote = '"' if (q1 or q2) else ""
        new_body = expand(body)
        if new_body != body:
            changed = True
            out.append(f"{prefix}{quote}{new_body}{quote}{trail}\n" if not line.endswith("\n") else f"{prefix}{quote}{new_body}{quote}\n")
        else:
            out.append(line)
    if changed:
        path.write_text("".join(out))
PY

rm -rf "$SKILLS_DIR"
mkdir -p "$SKILLS_DIR"
cp -R "$ROOT/platform/skills/." "$SKILLS_DIR/"
if [ -d "$ROOT/project/skills" ]; then
  cp -R "$ROOT/project/skills/." "$SKILLS_DIR/"
fi

echo "Activated: $(ls -1 "$RULES_DIR"/*.mdc | wc -l | tr -d ' ') rules, $(find "$SKILLS_DIR" -name 'SKILL.md' | wc -l | tr -d ' ') skills"
