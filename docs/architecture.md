# Architecture

## Navigation

- [Home](home.md)
- [Examples](examples.md)
- [Operations](operations.md)
- [Troubleshooting](troubleshooting.md)

## Fleet model

This chart manages a small Freqtrade fleet inside one Helm release. The public values model has only three top-level sections:

| Section | Role |
|---------|------|
| `global` | Shared defaults for image, security, scheduling, resources, and pod-level settings |
| `dashboard` | Optional shared `freqtrade webserver` instance for FreqUI and graphing |
| `bots[]` | Independent trading bots, one per strategy/runtime profile |

The chart intentionally does not model a privileged root bot.

## Dashboard

The dashboard is analysis-first:

- serves FreqUI and the `webserver` API
- stores its own user data on its own PVC
- can run companion `downloadData` jobs against the same PVC
- companion data jobs are scheduled onto the same node as the dashboard so `ReadWriteOnce` volumes remain mountable
- does not automatically aggregate bot state unless bot APIs are reachable and registered in the UI

## Bots

Each bot is isolated:

- one StatefulSet
- one ConfigMap for public config
- one Secret or ExternalSecret for private config
- one user-data PVC
- one API Service when enabled
- one Ingress when UI and ingress are enabled
- default startup state `running` unless `config.public.initial_state` overrides it

Bots share a chart release, but not runtime state. This keeps upgrades predictable while still keeping related bots together in one Helm release.

## Strategy Delivery

Bots support three strategy patterns:

- `image`: strategy shipped inside the container image
- `volume`: strategy code mounted from a dedicated PVC
- `initSync`: strategy fetched before start, usually from Git

`initSync` is the best fit for Git-managed strategy experiments. `image` is the best fit for immutable production delivery.

## Config model

The chart mirrors Freqtrade’s split between public and private config:

- `config.public` becomes `config.json`
- `config.secret` becomes `config-private.json`
- existing Secret and ExternalSecret flows are supported for the private file

The chart injects a small set of operational defaults so bot UX is sane by default:

- `dry_run` defaults from `mode`
- `initial_state` defaults to `running` for bots
- `api_server.enabled`, `listen_ip_address`, and `listen_port` are set when API or UI is enabled
- bot `api_server.CORS_origins` can default from `dashboard.ingress.host`

## Resource model

| Component | Resources |
|-----------|-----------|
| Dashboard | `StatefulSet`, headless Service, optional API Service, optional Ingress, ConfigMap, Secret or ExternalSecret, PVC, optional NetworkPolicy |
| Bot | `StatefulSet`, headless Service, optional API Service, optional Ingress, ConfigMap, Secret or ExternalSecret, PVC, optional strategy PVC, optional NetworkPolicy |
| Dashboard data job | `Job` or `CronJob` plus shared ConfigMap/Secret/PVC mounts |

The chart uses `StatefulSet` everywhere for long-running workloads because Freqtrade is singleton-oriented and often stores state locally in `user_data`.

## Network model

- Dashboard ingress is suitable for a shared analysis UI
- Bot ingress is optional and should be treated as an admin/API surface
- Private access or strongly protected ingress is preferred for bots
- Bots default API CORS from `dashboard.ingress.host` when `api.corsOrigins` is left empty. The chart emits both `https://<dashboard host>` and `http://<dashboard host>` to handle common ingress and TLS-termination patterns.

See [Operations](operations.md) and [Troubleshooting](troubleshooting.md) for operational guidance.
