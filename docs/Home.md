# Freqtrade Helm Chart Wiki

## Navigation

- [Architecture](Architecture.md)
- [Installation and Upgrades](Installation-and-Upgrades.md)
- [Examples](Examples.md)
- [Operations](Operations.md)
- [Releases and CI](Releases-and-CI.md)
- [Troubleshooting](Troubleshooting.md)
- [Generated Values Reference](../README.md#values)

## Overview

This chart manages a Freqtrade fleet inside one Helm release.

- `dashboard` is optional and runs `freqtrade webserver`
- `bots[]` contains one isolated StatefulSet per trading bot

The repo is the source of truth for these docs. If you maintain a GitHub wiki, copy or export the pages in this directory into the wiki repository.

The generated values reference stays in the repository `README.md` so it can be refreshed automatically from `values.yaml`.

## Recommended reading order

1. [Architecture](Architecture.md)
2. [Examples](Examples.md)
3. [Installation and Upgrades](Installation-and-Upgrades.md)
4. [Operations](Operations.md)
5. [Troubleshooting](Troubleshooting.md)
