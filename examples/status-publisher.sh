#!/bin/bash
# status-publisher - write a tiny JSON the dashboard widget can read (runs on a timer).
# Publishes: host name, container count, uptime, and optionally an upstream API balance.
# Writes IN PLACE because the dashboard mounts the file as a single-file bind: replacing
# the inode (mv / os.replace) would leave the container reading the old file forever.
set -uo pipefail

PUB=${STATUS_PUB:-$HOME/docker/homepage/public}
OUT="$PUB/status.json"
BALANCE_URL=${BALANCE_URL:-}          # e.g. https://api.example.com/user/balance
BALANCE_KEYFILE=${BALANCE_KEYFILE:-}  # file containing the bearer token, chmod 600
STATE=${STATUS_STATE:-$HOME/.status-history.json}

HOSTNAME_RAW=$(uname -n 2>/dev/null || echo server)
CONTAINERS=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
UPTIME_H=$(awk '{printf "%.1f", $1/3600}' /proc/uptime 2>/dev/null || echo "")

RAW=""
if [ -n "$BALANCE_URL" ] && [ -n "$BALANCE_KEYFILE" ] && [ -f "$BALANCE_KEYFILE" ]; then
  KEY=$(tr -d '\r\n' < "$BALANCE_KEYFILE")
  RAW=$(curl -s --max-time 15 -H "Authorization: Bearer $KEY" "$BALANCE_URL" || true)
fi

python3 - "$RAW" "$OUT" "$STATE" "$HOSTNAME_RAW" "$CONTAINERS" "$UPTIME_H" <<'PY'
import datetime, json, os, sys

raw, out, state, host_raw, containers, uptime_h = sys.argv[1:7]
now = datetime.datetime.now().astimezone()

balance = None
if raw.strip():
    try:
        d = json.loads(raw)
        infos = d.get("balance_infos") or []
        first = infos[0] if infos else {}
        balance = round(float(first.get("total_balance") or 0), 2)
    except Exception:
        balance = None

hist = []
if os.path.exists(state):
    try:
        hist = json.load(open(state))
    except Exception:
        hist = []
if balance is not None:
    hist.append({"t": now.isoformat(timespec="minutes"), "balance": balance})
    hist = hist[-4000:]

def parsed(h):
    return datetime.datetime.fromisoformat(h["t"])

midnight = now.replace(hour=0, minute=0, second=0, microsecond=0)
today = [h for h in hist if parsed(h) >= midnight]
spent_today = round(today[0]["balance"] - balance, 2) if balance is not None and len(today) >= 2 else None

payload = {
    "host": host_raw or "server",
    "containers": int(containers) if str(containers).strip().isdigit() else None,
    "uptime_hours": float(uptime_h) if str(uptime_h).strip() else None,
    "updated": now.strftime("%Y-%m-%d %H:%M"),
}
if balance is not None:
    payload["balance"] = balance
    payload["spent_today"] = spent_today

os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w") as f:          # in place, never os.replace (bind mount)
    json.dump(payload, f)
if balance is not None:
    json.dump(hist, open(state, "w"))
print(json.dumps(payload))
PY
