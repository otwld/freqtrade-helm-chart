# Examples

## Overview

The chart ships curated examples for common patterns. They are designed to be small and readable instead of comprehensive.

## Example Catalog

### `examples/minimal.yaml`

One bot, no ingress, API enabled. Best starting point for local development and port-forward access.

### `examples/dashboard-and-bots.yaml`

Shared dashboard plus multiple bots. Good reference for a small fleet.

### `examples/private-bot-ui.yaml`

Bot UI enabled, but no public ingress. Intended for operator use through port-forward or private networking.

### `examples/public-dashboard.yaml`

Dashboard with ingress and a companion data job for graph data. Good analysis-first deployment.

### `examples/external-secret.yaml`

Shows private config sourced from External Secrets Operator.

### `examples/existing-pvc.yaml`

Uses pre-provisioned storage instead of chart-managed PVCs.

### `examples/strategy-init-sync.yaml`

Shows Git-based strategy delivery with `initSync`.

### `examples/values-freqtrade-v2.yaml`

Integration-style example mirroring the live `freqtrade-v2` namespace used for chart validation.

## Usage

```bash
helm lint projects/charts/freqtrade -f projects/charts/freqtrade/examples/minimal.yaml
helm template test projects/charts/freqtrade -f projects/charts/freqtrade/examples/minimal.yaml
```

See [Operations](operations.md) for install and upgrade commands.
