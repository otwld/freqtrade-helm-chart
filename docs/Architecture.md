# Architecture

## Navigation

- [Home](Home.md)
- [Examples](Examples.md)
- [Operations](Operations.md)
- [Troubleshooting](Troubleshooting.md)

## Fleet Model

This chart manages a small Freqtrade fleet inside one Helm release.

- `dashboard` is optional and runs `freqtrade webserver`
- `bots[]` contains one StatefulSet per trading bot

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

Bots share a chart release, but not runtime state.

## Strategy Delivery

Bots support three strategy patterns:

- `image`: strategy shipped inside the container image
- `volume`: strategy code mounted from a dedicated PVC
- `initSync`: strategy fetched before start, usually from Git

`initSync` is the best fit for Git-managed strategy experiments. `image` is the best fit for immutable production delivery.

## Config Model

The chart mirrors Freqtrade’s split between public and private config:

- `config.public` becomes `config.json`
- `config.secret` becomes `config-private.json`
- existing Secret and ExternalSecret flows are supported for the private file

The chart injects `api_server` defaults when API or UI is enabled.

## Network Model

- Dashboard ingress is suitable for a shared analysis UI
- Bot ingress is optional and should be treated as an admin/API surface
- Private access or strongly protected ingress is preferred for bots

See [Operations](Operations.md) and [Troubleshooting](Troubleshooting.md) for operational guidance.
