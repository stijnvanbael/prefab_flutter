#!/usr/bin/env bash
# Checks that the backlog and the documentation agree with each other.
# Run from the repository root: tool/check_backlog.sh
# CI runs this on every pull request; fix every reported problem.
set -euo pipefail
shopt -s nullglob

errors=0
fail() {
  echo "ERROR: $*" >&2
  errors=$((errors + 1))
}

status_of() { sed -n 's/^status: *//p' "$1" | head -n 1 | tr -d "\"'"; }
id_of() { sed -n 's/^id: *//p' "$1" | head -n 1 | tr -d "\"'"; }

# 1. Done tasks live in backlog/completed, open tasks in backlog/tasks.
for f in backlog/tasks/*.md; do
  if [ "$(status_of "$f")" = "Done" ]; then
    fail "$f has status Done; move it with: git mv \"$f\" backlog/completed/"
  fi
done
for f in backlog/completed/*.md; do
  if [ "$(status_of "$f")" != "Done" ]; then
    fail "$f is in backlog/completed but its status is not Done"
  fi
done

# 2. Task ids are unique (two branches can pick the same next id).
dupes=$(for f in backlog/tasks/*.md backlog/completed/*.md; do
  id_of "$f"
done | tr '[:lower:]' '[:upper:]' | sort | uniq -d)
if [ -n "$dupes" ]; then
  fail "duplicate task ids: $(echo "$dupes" | tr '\n' ' ')- renumber the newest task"
fi

# 3. Every task referenced in the Known limitations table is still open.
open_ids=$(for f in backlog/tasks/*.md; do
  id_of "$f"
done | tr '[:lower:]' '[:upper:]')
limitations=$(sed -n '/^## Known limitations/,/^## /p' docs/user_guide.md)
for id in $(echo "$limitations" | grep -oE 'PF-[0-9]+' | sort -u); do
  if ! echo "$open_ids" | grep -qx "$id"; then
    fail "docs/user_guide.md Known limitations references $id, which is not an open task in backlog/tasks"
  fi
done

# 4. Every milestone a task refers to exists.
milestone_ids=$(for f in backlog/milestones/*.md; do
  id_of "$f"
done)
for f in backlog/tasks/*.md backlog/completed/*.md; do
  m=$(sed -n 's/^milestone: *//p' "$f" | head -n 1 | tr -d "\"'")
  if [ -z "$m" ]; then continue; fi
  if ! echo "$milestone_ids" | grep -qx "$m"; then
    fail "$f refers to milestone '$m', which has no file in backlog/milestones"
  fi
done

if [ "$errors" -gt 0 ]; then
  echo "$errors backlog problem(s) found." >&2
  exit 1
fi
echo "Backlog OK."
