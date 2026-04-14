# Releases and CI

## Navigation

- [Home](home.md)
- [Installation and Upgrades](installation_and_upgrades.md)
- [Operations](operations.md)

## Workflow overview

The repository ships three GitHub Actions workflows:

| Workflow | Purpose |
|----------|---------|
| `CI` | Regenerate README, lint the chart, lint all examples, and package the chart |
| `Release Readiness` | Re-validate tagged builds and ensure tag-to-chart-version alignment |
| `Publish Chart` | Publish release assets and mirror the chart into the central `helm-charts` repo backing `https://helm.otwld.com/` |

The published install path for consumers is:

```bash
helm repo add otwld https://helm.otwld.com/
helm repo update
helm upgrade --install freqtrade otwld/freqtrade --namespace freqtrade --create-namespace
```

## Maintainer workflow

Before opening a PR:

```bash
./scripts/generate-docs.sh
helm lint .
./scripts/lint-examples.sh .
helm package . --destination /tmp
```

Before tagging a release:

1. Update `Chart.yaml` version intentionally.
2. Re-run local validation.
3. Confirm examples still reflect the supported values model.
4. Push the tag.
5. Inspect both `Release Readiness` and `Publish Chart`.
6. Confirm the chart is available from `https://helm.otwld.com/`.

## Release prerequisites

The publish workflow expects:

- `GITHUB_TOKEN` with release/index permissions in this repository
- `HELM_CHARTS_REPO_TOKEN` with push access to `otwld/helm-charts`

The central mirror writes this chart to `charts/freqtrade` in the `helm-charts` repository.

## Repository metadata

The repository metadata lives in `.github/settings.yml`:

- description
- homepage
- wiki enablement
- topics
- default branch

If your GitHub organization uses a settings-sync app, that file becomes the source of truth for repo metadata as well.

## Wiki export

The repository remains the source of truth for docs. To copy wiki-ready pages into a cloned GitHub wiki repository:

```bash
./scripts/export-wiki.sh ../freqtrade-helm-chart.wiki
```
