# Freqtrade Helm Chart

Fleet-oriented Helm chart for running Freqtrade dashboards and trading bots on Kubernetes.

This chart is designed around two first-class concepts:

- `dashboard`: an optional shared `freqtrade webserver` instance for analysis and graphing
- `bots[]`: one or more isolated trading bots, each with its own config, secret, storage, service, and optional ingress

## Highlights

- Fleet model with one release managing a dashboard and multiple bots
- One isolated StatefulSet per bot
- Per-instance ConfigMap, Secret, PVC, Service, and Ingress
- Strategy delivery via image, PVC, or `initSync`
- Dashboard companion data jobs for graph and pair data
- Render-time validation for common Freqtrade misconfigurations
- Operational helper script for bot login details and local port-forwards

## Quick Start

```bash
helm lint projects/charts/freqtrade
helm upgrade --install freqtrade-v2 projects/charts/freqtrade \
  -n freqtrade-v2 \
  -f projects/charts/freqtrade/examples/minimal.yaml
```

Useful follow-up commands:

```bash
helm template freqtrade-v2 projects/charts/freqtrade \
  -f projects/charts/freqtrade/examples/dashboard-and-bots.yaml

projects/charts/freqtrade/scripts/bot-access.sh list
projects/charts/freqtrade/scripts/bot-access.sh start
```

## Architecture

The chart uses one shared instance schema for both the dashboard and bots:

- runtime: image, args, env, resources, scheduling
- exposure: API, UI, Service, Ingress
- configuration: `config.public` + `config.secret`
- storage: `persistence`
- strategy delivery: `strategy.source`

Each bot remains operationally independent even though they share one Helm release.

Read more:

- [Docs index](docs/README.md)
- [Architecture](docs/architecture.md)
- [Operations](docs/operations.md)
- [Examples](docs/examples.md)
- [Troubleshooting](docs/troubleshooting.md)

## Values Structure

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

## Upgrade Workflow

Recommended workflow:

```bash
projects/charts/freqtrade/scripts/lint-examples.sh

helm upgrade --install freqtrade-v2 projects/charts/freqtrade \
  -n freqtrade-v2 \
  -f projects/charts/freqtrade/examples/values-freqtrade-v2.yaml
```

If Helm release metadata is unhealthy, use the recovery runbook in [docs/operations.md](docs/operations.md).

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

Use the focused example:

- [`examples/bot-with-telegram.yaml`](examples/bot-with-telegram.yaml)

Official Freqtrade references:

- https://www.freqtrade.io/en/stable/telegram-usage/
- https://www.freqtrade.io/en/stable/configuration/

## Security Notes

- Treat bot APIs as operator surfaces, not public apps
- Prefer private access or strongly protected ingress for bot UIs
- Keep exchange keys in `config.secret`, existing Secrets, or ExternalSecrets
- Do not expose the dashboard and bot APIs with the same security assumptions

## Repository Layout

```text
freqtrade/
├── README.md
├── docs/
├── examples/
├── scripts/
├── templates/
├── values.yaml
└── values.schema.json
```
