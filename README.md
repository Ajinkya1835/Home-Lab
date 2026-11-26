[![check](https://github.com/Ajinkya1835/Home-Lab/actions/workflows/check.yml/badge.svg?branch=main)](https://github.com/Ajinkya1835/Home-Lab/actions/workflows/check.yml) This repository contains a reusable Docker Compose example for Homepage, a static demo, and operator documentation; it does not include complete host provisioning for a running homelab.

## Services

| Compose file | Service | Image |
|---|---|---|
| [`examples/compose.homepage.yaml`](examples/compose.homepage.yaml) | `homepage` | `ghcr.io/gethomepage/homepage:latest` |

This is the only Compose file in the repository that defines a service.

## Backups & monitoring

The included Compose example defines no backup or monitoring services. The [runbook](docs/runbook.md) describes host-specific backup, restore, and status procedures; these are not provisioned by this repository's example stack.

## Rebuild from scratch

To run the Homepage example:

1. Install Docker Engine and the Compose plugin.
2. Copy `examples/compose.homepage.yaml` into a deployment directory as `compose.yaml`. Create the `.env` file and `config/` and `public/` files referenced by the Compose file.
3. Ensure the external Docker network `netdata_default` exists, and replace the sample `HOMEPAGE_ALLOWED_HOSTS` entry with your own host.
4. From the deployment directory, validate and start the service:

   ```sh
   docker compose config
   docker compose up -d
   ```

This only rebuilds the example service. Host installation and restoration steps are specific to your machine; see the [runbook](docs/runbook.md).

## Architecture

> **Architecture diagram placeholder:** Add a current, sanitized diagram of your deployment here.
