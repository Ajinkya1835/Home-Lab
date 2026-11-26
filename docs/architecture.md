# Architecture

## Request path

```mermaid
sequenceDiagram
    participant C as Client (on tailnet)
    participant T as Tailscale (WireGuard)
    participant S as tailscale serve
    participant D as Container on 127.0.0.1
    C->>T: https://<host>.ts.net:8444
    T->>S: decrypted, authenticated by device identity
    S->>D: proxy http://127.0.0.1:2283
    D-->>C: response
```

Public visitors take the same path through **Funnel**, but only the `edge` container is mapped
to it.

## Deploy loop

```mermaid
flowchart LR
    A[git push] --> B[CI: compose config, shellcheck, gitleaks]
    B --> C[main]
    C --> D[host cron: deploy every 5 min]
    D -->|compose hash changed?| E[docker compose up -d for that stack only]
    D -->|pull fails| F[event + push notification]
```

## Storage

| Mount | Device | Use |
|---|---|---|
| `/` | SSD | OS, Docker, app configs |
| `/mnt/hdd1` | LUKS2 HDD | Immich library, personal files |
| `/mnt/backup` | HDD | Nightly backups, media library, read-only file share |

## Network layout

`homepage` joins the per-stack networks (`immich_default`, `jellyfin_default`, `netdata_default`,
`scrutiny_default`) so it can query widget APIs by container name. No other stack joins another's
network, which keeps the dependency graph acyclic: `homepage` is always started last.
