# Releases and CI

## Navigation

- [Home](Home.md)
- [Installation and Upgrades](Installation-and-Upgrades.md)
- [Operations](Operations.md)

## CI workflow

The repository ships two GitHub Actions workflows:

- `CI`
  - runs `./scripts/generate-docs.sh`
  - verifies `README.md` is current
  - runs `helm lint .`
  - runs `./scripts/lint-examples.sh .`
  - packages the chart as an artifact
- `Release Readiness`
  - runs `./scripts/generate-docs.sh`
  - verifies `README.md` is current
  - validates chart metadata
  - validates tag-to-chart version alignment
  - lints and renders examples
  - packages the chart and uploads the archive as an artifact
- `Publish Chart`
  - runs on version tags and manual dispatch
  - reruns validation and packaging
  - publishes release assets with `chart-releaser`
  - updates the repository chart index
  - mirrors the chart sources into the central `helm-charts` repository used by `https://helm.otwld.com/`

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
