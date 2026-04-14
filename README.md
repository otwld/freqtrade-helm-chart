# Freqtrade Helm Chart

[![CI](https://github.com/otwld/freqtrade-helm-chart/actions/workflows/ci.yaml/badge.svg)](https://github.com/otwld/freqtrade-helm-chart/actions/workflows/ci.yaml)
[![Release Readiness](https://github.com/otwld/freqtrade-helm-chart/actions/workflows/release-readiness.yaml/badge.svg)](https://github.com/otwld/freqtrade-helm-chart/actions/workflows/release-readiness.yaml)

Production-grade Helm chart for running Freqtrade dashboards and multi-bot fleets on Kubernetes.

The chart is built around two first-class concepts:

- `dashboard`: an optional shared `freqtrade webserver` instance for analysis, graphing, and pair data
- `bots[]`: one or more isolated trading bots, each with its own config, secret, strategy source, storage, service, and optional ingress

## Why this chart

- Fleet-oriented model with one release managing a dashboard and multiple bots
- One isolated StatefulSet per bot and one isolated StatefulSet for the dashboard
- Per-instance ConfigMap, Secret, PVC, Service, and Ingress
- Strategy delivery via image, PVC, or `initSync`
- Dashboard companion data jobs for graph and pair data
- Render-time validation for common Freqtrade misconfigurations
- Operator helper scripts for example linting and local bot access

## Quick start

```bash
helm lint .
./scripts/lint-examples.sh .

helm upgrade --install freqtrade ./ \
  --namespace freqtrade \
  --create-namespace \
  -f examples/minimal.yaml
```

Useful follow-up commands:

```bash
helm template freqtrade . -f examples/dashboard-and-bots.yaml

./scripts/bot-access.sh list
./scripts/bot-access.sh start
```

## Architecture at a glance

The chart uses one shared instance schema for both the dashboard and bots:

- runtime: image, args, env, resources, scheduling
- exposure: API, UI, Service, Ingress
- configuration: `config.public` + `config.secret`
- storage: `persistence`
- strategy delivery: `strategy.source`

Each bot remains operationally independent even though they share one Helm release.

## Documentation

The repo is the source of truth for the handbook and is structured so it can be copied directly into a GitHub wiki.

- [Wiki Home](docs/Home.md)
- [Architecture](docs/Architecture.md)
- [Installation and Upgrades](docs/Installation-and-Upgrades.md)
- [Examples](docs/Examples.md)
- [Operations](docs/Operations.md)
- [Releases and CI](docs/Releases-and-CI.md)
- [Troubleshooting](docs/Troubleshooting.md)

To export the handbook into a checked-out GitHub wiki repository:

```bash
./scripts/export-wiki.sh /path/to/freqtrade-helm-chart.wiki
```

## Values model

Top-level values are intentionally small:

- `global`: shared defaults
- `dashboard`: optional shared webserver instance
- `bots`: list of independent bot instances

The main `values.yaml` is intentionally comment-heavy and example-light. Curated patterns live under [`examples/`](examples/).

## Examples

Curated examples shipped with the chart:

- [`examples/minimal.yaml`](examples/minimal.yaml)
- [`examples/bot-with-telegram.yaml`](examples/bot-with-telegram.yaml)
- [`examples/dashboard-and-bots.yaml`](examples/dashboard-and-bots.yaml)
- [`examples/private-bot-ui.yaml`](examples/private-bot-ui.yaml)
- [`examples/public-dashboard.yaml`](examples/public-dashboard.yaml)
- [`examples/external-secret.yaml`](examples/external-secret.yaml)
- [`examples/existing-pvc.yaml`](examples/existing-pvc.yaml)
- [`examples/strategy-init-sync.yaml`](examples/strategy-init-sync.yaml)
- [`examples/values-freqtrade-v2.yaml`](examples/values-freqtrade-v2.yaml)

## Telegram

Telegram is configured per bot through `bots[].telegram`.

- Required when enabled:
  - `telegram.token`
  - `telegram.chatId`
- Optional upstream-aligned fields:
  - `topicId`
  - `authorizedUsers`
  - `allowCustomMessages`
  - `reload`
  - `balanceDustLevel`
  - `notificationSettings`
  - `keyboard`

The chart renders Telegram as a dedicated secret-backed config overlay, so `token` and `chatId` stay out of `config.public`.

Reference example:

- [`examples/bot-with-telegram.yaml`](examples/bot-with-telegram.yaml)

Official Freqtrade references:

- https://www.freqtrade.io/en/stable/telegram-usage/
- https://www.freqtrade.io/en/stable/configuration/

## Security notes

- Treat bot APIs as operator surfaces, not public apps
- Prefer private access or strongly protected ingress for bot UIs
- Keep exchange keys in `config.secret`, existing Secrets, or ExternalSecrets
- Do not expose the dashboard and bot APIs with the same security assumptions

## Repository layout

```text
freqtrade-helm-chart/
├── .github/
├── docs/
├── examples/
├── scripts/
├── templates/
├── CONTRIBUTING.md
├── Chart.yaml
├── README.md
├── values.yaml
└── values.schema.json
```
