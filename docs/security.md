# Security model

## Layers

| Layer | Control |
|---|---|
| Network | Tailscale mesh; `ufw` default-deny, rules scoped to `tailscale0`; only `41641/udp` open for direct WireGuard |
| Exposure | One public endpoint (`edge`, static). Password manager, photos, automation and admin UIs are tailnet-only |
| Binding | Every container publishes `127.0.0.1:<port>`, never `0.0.0.0` |
| Containers | `no-new-privileges`, log rotation, `cap_drop: [ALL]` where possible, non-root user where the image supports it |
| Secrets | `.env` untracked, `.env.example` names only, gitleaks in CI, CI blocks private IPs / tailnet hostnames |
| Host | Key-only SSH (`host/sshd_config.d`), fail2ban, unattended security upgrades |
| Data | LUKS2 on the data disk, nightly backups, S.M.A.R.T. alerts via Scrutiny |

## Known trade-offs

- **Docker socket mounts.** Homepage, Dozzle and Netdata mount `docker.sock` as `:ro`. Read-only
  on the socket file does *not* make the Docker API read-only; anything with that socket can
  still start containers. Mitigation on the roadmap: a socket proxy that allows only `GET`.
- **Root in containers.** Several upstream images run as root. `no-new-privileges` and dropped
  capabilities limit the blast radius but do not remove it.
- **Single node, single site.** Backups are on a second disk in the same machine. Fire, theft
  or a power surge takes both. Off-site copy is on the roadmap.
- **Auto-deploy from git.** The 5-minute deploy loop trusts `main`. Protect the branch and
  require review/CI before merge.

## Checklist before exposing anything new

1. Does it hold credentials or personal data? → tailnet-only, no Funnel.
2. Bound to `127.0.0.1`? Pinned tag? `no-new-privileges`?
3. Added to `host/tailscale-serve.sh` and the dashboard?
4. `make validate` green?
