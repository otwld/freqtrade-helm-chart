# Troubleshooting

## Navigation

- [Home](home.md)
- [Installation and Upgrades](installation_and_upgrades.md)
- [Operations](operations.md)

## Pod starts then exits immediately

Check the pod logs first:

```bash
kubectl logs -n <namespace> statefulset/<release>-bot-<name>
kubectl logs -n <namespace> statefulset/<release>-dashboard
```

Common causes:

- missing `pairlists`
- `StaticPairList` without `exchange.pair_whitelist`
- missing `entry_pricing` / `exit_pricing` for bots
- invalid strategy sync command

## UI shows bots as offline

Common causes:

- bot API is not reachable from the browser
- bot `api.corsOrigins` does not match the dashboard origin
- wrong username/password stored in the UI

For local access, use [`scripts/bot-access.sh`](../scripts/bot-access.sh).

If `api.corsOrigins` is empty, the chart only defaults bot CORS from `dashboard.ingress.host` when the dashboard ingress is enabled and has a host.

## UI shows bots online but no trades happen

Check the bot application state in the logs or API.

The chart now defaults bots to `initial_state: running`, but a bot can still be paused if:

- `config.public.initial_state` was explicitly set to `stopped`
- someone stopped it through the UI or API
- the pod was rolled from an older revision that did not set the startup state you expected

## Graph page has no pairs

The dashboard needs downloaded OHLCV data on its PVC.

Check:

- `dashboard.dataJobs.enabled`
- `dashboard.dataJobs.downloadData.enabled`
- job completion
- dashboard `user_data/data` contents
- whether the job is co-located with the dashboard when using `ReadWriteOnce` storage

## Strategies dropdown is empty

The instance serving the UI must have strategy files available in its own `user_data/strategies` path.

Check:

- strategy delivery mode
- `initSync` logs
- strategy file names and class names

## Helm release cannot upgrade

Symptoms:

- `helm status` shows `superseded`
- `helm history` contains a failed or pending upgrade with no deployed revision

Use the recovery runbook in [Operations](operations.md).
