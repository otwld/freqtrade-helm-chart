# Operations

## Navigation

- [Home](Home.md)
- [Installation and Upgrades](Installation-and-Upgrades.md)
- [Examples](Examples.md)
- [Troubleshooting](Troubleshooting.md)

## Local install

```bash
helm upgrade --install freqtrade . \
  -n freqtrade \
  -f examples/dashboard-and-bots.yaml \
  --create-namespace
```

## Upgrade workflow

Recommended preflight:

```bash
./scripts/generate-docs.sh
./scripts/lint-examples.sh .
helm lint . -f examples/values-freqtrade-v2.yaml
helm template freqtrade . -f examples/values-freqtrade-v2.yaml >/tmp/freqtrade-rendered.yaml
```

Upgrade:

```bash
helm upgrade --install freqtrade . \
  -n freqtrade \
  -f examples/values-freqtrade-v2.yaml
```

## Access bots locally

Use the helper script:

```bash
./scripts/bot-access.sh list
./scripts/bot-access.sh start
./scripts/bot-access.sh status
./scripts/bot-access.sh stop
```

## Bot onboarding checklist

For each new bot:

1. Add a new `bots[]` entry.
2. Set `name`, `mode`, `strategy`, `config.public`, and private API credentials.
3. Set `enabled: false` only when you want the bot to stay in values without rendering resources.
4. Choose a strategy delivery pattern:
   - `image` for immutable production delivery
   - `initSync` for Git-based experimentation
   - `volume` when strategies are managed outside the chart
5. Decide whether the bot should expose:
   - API only
   - UI + private ingress
   - no ingress, port-forward only
6. If the bot should be reachable from the shared dashboard UI, either:
   - leave `api.corsOrigins` empty and let the chart default from `dashboard.ingress.host`
   - or set `api.corsOrigins` explicitly for custom origins
7. If Telegram is required, configure `bots[].telegram`.
8. By default the chart sets `config.public.initial_state=running`. Override it to `stopped` only when you intentionally want the bot to boot paused.
9. Run `helm lint` and `helm template`.
10. Upgrade the release.

## Release recovery

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

## Telegram setup

The chart exposes Telegram only for bots through `bots[].telegram`.

Minimal shape:

```yaml
bots:
  - name: sample
    enabled: true
    telegram:
      enabled: true
      token: "123456:bot-token"
      chatId: "123456789"
```

Supported chart fields map directly to the current stable Freqtrade model:

- `enabled`
- `token`
- `chatId`
- `topicId`
- `authorizedUsers`
- `allowCustomMessages`
- `reload`
- `balanceDustLevel`
- `notificationSettings`
- `keyboard`

Notes:

- keep `token` and `chatId` in secure values handling
- do not also define `config.public.telegram` or `config.secret.telegram` when using `bots[].telegram`
- use `topicId` and `authorizedUsers` for Telegram group/forum setups

Reference example:

- [`../examples/bot-with-telegram.yaml`](../examples/bot-with-telegram.yaml)

Official upstream docs:

- https://www.freqtrade.io/en/stable/telegram-usage/
- https://www.freqtrade.io/en/stable/configuration/

## Related docs

- [Architecture](Architecture.md)
- [Examples](Examples.md)
- [Troubleshooting](Troubleshooting.md)
