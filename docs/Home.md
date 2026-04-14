# Freqtrade Helm Chart Wiki

## Navigation

- [Architecture](Architecture.md)
- [Installation and Upgrades](Installation-and-Upgrades.md)
- [Examples](Examples.md)
- [Operations](Operations.md)
- [Releases and CI](Releases-and-CI.md)
- [Troubleshooting](Troubleshooting.md)
- [Generated Values Reference](../README.md#values)

## What this chart is for

This chart manages a small Freqtrade fleet inside one Helm release:

- `dashboard` is an optional analysis-first `freqtrade webserver`
- `bots[]` contains one isolated trading bot per strategy/runtime profile
- `dashboard.dataJobs` populate historical candle data for graph pages

The chart intentionally does not model a privileged root bot. That keeps the public API small and makes resource ownership explicit.

## Documentation source of truth

The repository is the source of truth for these docs. If you maintain a GitHub wiki, copy or export the pages in this directory into the wiki repository with:

```bash
./scripts/export-wiki.sh /path/to/freqtrade-helm-chart.wiki
```

The generated values reference stays in [README.md](../README.md#values) so it can be refreshed automatically from `values.yaml`.

## Recommended reading order

1. [Architecture](Architecture.md)
2. [Examples](Examples.md)
3. [Installation and Upgrades](Installation-and-Upgrades.md)
4. [Operations](Operations.md)
5. [Troubleshooting](Troubleshooting.md)
