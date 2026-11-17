# Homelab — self-hosted, reproducible, and boring on purpose

A single Ubuntu box that runs 14 containers behind Tailscale, backs itself up nightly,
watches its own disks, and tells me on Telegram when something goes wrong. The whole
server config is a git repo, so the machine can be rebuilt from the last commit.

**[→ Live demo](https://your-github-user.github.io/homelab/demo/)** · [Architecture map](docs/architecture.html) · [Runbook](docs/runbook.md)

![Dashboard](docs/dashboard.png)

---

## Why this exists

I rebuilt this machine after its boot drive failed and lost nothing. That only worked
because the server's configuration, not just its data, lived in git. Since then the rule
is simple: **if it is not in the repo, it does not exist**, and every deployment path is
automated so that restoring is the same operation as running it the first time.

## What it runs

| Layer | Choice | Notes |
|---|---|---|
| Host | Ubuntu 22.04 · AMD laptop silicon · 5.7 GiB RAM + 2 GiB swap | repurposed laptop, always-on |
| Data | LUKS-encrypted hdd1 + separate backup disk | unlocked at boot, mounted via fstab |
| Network | Tailscale (WireGuard) | no router port-forwards; three public Funnel endpoints only |
| Runtime | Docker Compose | one compose file per stack, validated in CI |
| Dashboard | [Homepage](https://gethomepage.dev) | widgets for every service + live netdata |
| Media | Jellyfin, Immich (server + ML + Postgres + Redis), File Browser | photos, films, files |
| Ops | Netdata, Dozzle, Scrutiny, Tab Status, noVNC | metrics, logs, SMART, status page |
| Automation | n8n, cron | outreach pipelines, snapshots, backups |
| Secrets | Vaultwarden | self-hosted password vault |

## Exposure model

Nothing is published by default. Everything is either:

* **public** — an explicit Tailscale Funnel endpoint (media streaming, photo sharing, vault),
* **tailnet only** — reachable from my own devices, never from the internet, or
* **internal** — container-to-container on a private bridge network.

Ports and paths are drawn in the [architecture map](docs/architecture.html); the map is
generated from the same config the server runs, so it cannot drift quietly.

## Automation

```
03:00  backup            encrypted snapshot of config + database dumps
03:30  server-doc        regenerate the server inventory (docs/server/SERVER.md)
03:40  sync-config       copy live config into the repo, commit, push (gitleaks-gated)
*/5    deploy            pull, validate compose, `up -d` only what changed
*/10   server-snapshot   docs-only commit, tagged [skip ci]
*/15   status            publish dashboard status json (balance, containers, uptime)
08:00  status-digest     one morning message: what changed, what is red
```

Failures never go to email. Callers write a structured event to a shared spool; a small
agent job forwards new events to Telegram with dedupe, so one broken stack is one message,
not a mail storm.

## CI/CD

Two workflows keep the repo honest:

1. **validate** — every `docker/*/compose*.y*ml` is resolved with
   `docker compose config -q --no-interpolate` (catches duplicate keys, bad anchors,
   merge surprises), `shellcheck` on deploy scripts, `gitleaks` on every push and PR.
2. **deploy** — the server pulls on a 5-minute timer, re-validates, and recreates only
   the stacks whose compose hash changed. A failed validation leaves the old container
   running and posts a high-priority event.

## Three things this repo taught me

**Duplicate merge keys are silent until CI catches them.** A base compose file declared
`group_add: ["video", "110"]`; an override added `110` again. Compose merges lists, so the
stack failed validation with *"group_add items at 1 and 2 are equal"* — and, because a
nightly job copies live config into the repo, the failure kept reappearing after every
"fix". Live config is the source of truth; fix it there first.

**A directory mount can hide an application's own assets.** Mounting `./public` over
`/app/public` in the dashboard container looked harmless — until every UI label rendered
as a raw i18n key (`resources.cpu`, `wmo.0-night`) because the image's `locales/`
directory was buried under my mount. Bind individual files, never a whole asset directory.

**Bind mounts follow inodes.** A status file written with `os.replace()` (new inode) never
reached the container — it kept serving the old file forever. Write in place when the
target is a single-file bind.

## Repo layout

```
docker/<stack>/      compose + config for every service
bin/                 deploy, backup, snapshot, sync-config, status, event
host/                machine-level config captured for rebuild (sshd, cron, fstab, systemd)
docs/                architecture map, runbook, dashboard screenshot
examples/            sanitized compose + CI snippets you can reuse
demo/                static showcase page (GitHub Pages)
```

## Reusing any of this

`examples/` holds copy-paste-ready pieces: a hardened Homepage compose file, the CI
workflow, and the status-publishing script. They contain placeholder hostnames — swap in
your own. Nothing in this repo carries a real credential; secrets live on the host and are
excluded by `.gitignore` plus a gitleaks gate.

## License

MIT — take what is useful.
