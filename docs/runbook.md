# Runbook

How the server is built, deployed, backed up and restored. Everything here is executed by
cron or by the deploy loop — these commands exist for the day that loop is broken.

## Daily loop

| Time | Job | Command |
|---|---|---|
| 03:00 | backup | `~/bin/backup` |
| 03:30 | server inventory | `~/bin/server-doc` |
| 03:40 | config into git | `~/bin/sync-config` |
| every 5 min | deploy changed stacks | `~/bin/deploy` |
| every 10 min | docs snapshot | `~/bin/server-snapshot` |
| every 15 min | dashboard status json | `~/bin/deepseek-balance` |
| 08:00 | morning digest | `~/bin/status-digest` |

`sync-config` copies live stack config into the repository, refuses to commit when a file
looks like it contains a secret, and pushes. `deploy` pulls, validates, recreates only the
stacks whose compose hash changed, and writes a structured event on failure.

## Deploying by hand

```bash
cd ~/Home-Lab
git pull --rebase --autostash
for d in docker/*/; do
  f=$(ls "$d"compose.y*ml "$d"docker-compose.y*ml 2>/dev/null | head -1); [ -n "$f" ] || continue
  if [ -f "$d.env.example" ]; then cp "$d.env.example" "$d.env"; else touch "$d.env"; fi
  (cd "$d" && docker compose config -q --no-interpolate) || echo "INVALID: $d"
done
~/bin/deploy           # or: cd docker/<stack> && docker compose up -d
```

## Adding a stack

1. `mkdir docker/<name>` with a `compose.yaml`, and an `.env.example` if it needs variables.
2. Add it to the dashboard (`docker/homepage/config/services.yaml`) if it should be visible.
3. Run the validation loop above; the next deploy picks it up automatically.
4. `sync-config` commits it to the repo on the nightly run (or run it manually).

## Restoring a service

```bash
cd ~/docker/<stack>
docker compose down
cp -a ~/Home-Lab/docker/<stack>/compose.yaml .
docker compose up -d
docker compose logs -f --tail 50
```

Config for most stacks lives in `~/docker/<stack>/config` and is mirrored in the repo, so
`git checkout -- docker/<stack>` restores a known-good version.

## When something is red

1. `docker ps -a --format '{{.Names}}\t{{.Status}}'` — is it even running?
2. `docker logs <name> --tail 80` — the error is almost always the first 10 lines.
3. `docker compose config -q` in the stack directory — merge or YAML errors surface here.
4. CI has the same validation, so a green CI plus a broken container means the problem is
   runtime (ports, permissions, missing network), not config.

## Restoring the host

1. Install Ubuntu, create the user, add the SSH key.
2. Clone the repo to `~/Home-Lab`.
3. Restore `host/` files (fstab, sshd, cron) and unlock the LUKS data disk.
4. `~/bin/deploy` twice: the first run records a baseline, the second brings stacks up.
5. Verify from the dashboard, then re-enable the timers.

## Secrets

Never in git. Live `.env` files stay on the host, `.env.example` files (variable names,
no values) are what the repo carries, and `gitleaks` runs on every push.
