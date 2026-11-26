#!/usr/bin/env bash
# Validate every stack the same way CI does. Usage: scripts/validate.sh
set -uo pipefail
cd "$(dirname "$0")/.."
fail=0
for d in docker/*/; do
  f=$(ls "$d"compose.y*ml 2>/dev/null | head -1); [ -n "$f" ] || continue
  made=0
  if [ ! -f "$d.env" ]; then
    if [ -f "$d.env.example" ]; then cp "$d.env.example" "$d.env"; else : > "$d.env"; fi
    made=1
  fi
  if (cd "$d" && docker compose config -q); then echo "ok      $d"; else echo "INVALID $d"; fail=1; fi
  [ "$made" = 1 ] && rm -f "$d.env"
done
exit $fail
