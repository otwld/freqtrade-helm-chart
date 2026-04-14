# Examples

## Navigation

- [Home](Home.md)
- [Installation and Upgrades](Installation-and-Upgrades.md)
- [Operations](Operations.md)

## Overview

The chart ships curated examples for common patterns. They are designed to be small and readable instead of comprehensive.

## Example Catalog

| File | Best for | Notes |
|------|----------|-------|
| `examples/minimal.yaml` | First local install | One bot, no ingress, API enabled |
| `examples/bot-with-telegram.yaml` | Telegram setup | Uses the chart-managed `bots[].telegram` block |
| `examples/dashboard-and-bots.yaml` | Small multi-bot fleet | Shared dashboard plus multiple bots |
| `examples/recommended-fleet.yaml` | Production-style baseline | Public dashboard, private bots, existing secrets |
| `examples/private-bot-ui.yaml` | Private operator workflows | Bot UI enabled, no public ingress |
| `examples/public-dashboard.yaml` | Shared graphing UI | Public dashboard plus recurring `download-data` job |
| `examples/external-secret.yaml` | ESO integration | Private config sourced from External Secrets Operator |
| `examples/existing-pvc.yaml` | Storage reuse | Uses pre-provisioned PVCs instead of chart-managed claims |
| `examples/strategy-init-sync.yaml` | Git-managed strategies | Pulls strategy code with `initSync` |
| `examples/values-freqtrade-v2.yaml` | Full integration overlay | Mirrors the larger validation namespace used during chart development |

## Choosing the right example

- Start from `minimal.yaml` if you are validating the chart locally.
- Start from `recommended-fleet.yaml` if you want a production-style baseline.
- Start from `dashboard-and-bots.yaml` if you want a small fleet with a shared UI.
- Start from `public-dashboard.yaml` if graph pages matter more than per-bot ingress.

## Usage

```bash
helm lint . -f examples/minimal.yaml
helm template test . -f examples/minimal.yaml
```

See [Installation and Upgrades](Installation-and-Upgrades.md) for install and upgrade commands.
