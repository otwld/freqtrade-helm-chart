# Operations

## Install

```bash
helm upgrade --install freqtrade-v2 projects/charts/freqtrade \
  -n freqtrade-v2 \
  -f projects/charts/freqtrade/examples/dashboard-and-bots.yaml \
  --create-namespace
```

## Upgrade

Recommended preflight:

```bash
projects/charts/freqtrade/scripts/lint-examples.sh
helm lint projects/charts/freqtrade -f projects/charts/freqtrade/examples/values-freqtrade-v2.yaml
helm template freqtrade-v2 projects/charts/freqtrade \
  -f projects/charts/freqtrade/examples/values-freqtrade-v2.yaml >/tmp/freqtrade-v2-rendered.yaml
```

Upgrade:

```bash
helm upgrade --install freqtrade-v2 projects/charts/freqtrade \
  -n freqtrade-v2 \
  -f projects/charts/freqtrade/examples/values-freqtrade-v2.yaml
```

## Access Bots Locally

Use the helper script:

```bash
projects/charts/freqtrade/scripts/bot-access.sh list
projects/charts/freqtrade/scripts/bot-access.sh start
projects/charts/freqtrade/scripts/bot-access.sh status
projects/charts/freqtrade/scripts/bot-access.sh stop
```

## Release Recovery

If `helm status` shows `superseded`, `pending-upgrade`, or no deployed revision:

1. Render the chart with the exact values file you intend to run.
2. Compare the rendered resources with the live namespace.
3. Confirm live objects still carry Helm ownership annotations:
   - `meta.helm.sh/release-name`
   - `meta.helm.sh/release-namespace`
   - `app.kubernetes.io/managed-by=Helm`
4. Run a Helm-native reconciliation upgrade.
5. If Helm metadata is still stuck, remove only the broken release metadata secrets for the failed pending revision and retry the same upgrade.
6. Avoid continuing with `kubectl apply` as a steady-state workflow, or future upgrades will drift again.

## Bot Onboarding

For each new bot:

1. Add a new `bots[]` entry.
2. Set `name`, `mode`, `strategy`, `config.public`, and private API credentials.
3. Decide whether the bot should expose:
   - API only
   - UI + private ingress
   - no ingress, port-forward only
4. Run `helm lint` and `helm template`.
5. Upgrade with `--atomic`.

## Related Docs

- [Architecture](architecture.md)
- [Examples](examples.md)
- [Troubleshooting](troubleshooting.md)
