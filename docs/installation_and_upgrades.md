# Installation and Upgrades

## Navigation

- [Home](home.md)
- [Examples](examples.md)
- [Operations](operations.md)
- [Releases and CI](releases_and_ci.md)

## Install

```bash
helm repo add otwld https://helm.otwld.com/
helm repo update
helm upgrade --install freqtrade otwld/freqtrade \
  --namespace freqtrade \
  --create-namespace \
  -f values.yaml
```

## Local development install

```bash
helm upgrade --install freqtrade . \
  --namespace freqtrade \
  --create-namespace \
  -f examples/dashboard-and-bots.yaml
```

## Recommended preflight

```bash
./scripts/generate-docs.sh
./scripts/lint-examples.sh .
helm lint . -f examples/values-freqtrade-v2.yaml
helm template freqtrade . -f examples/values-freqtrade-v2.yaml >/tmp/freqtrade-rendered.yaml
```

## Upgrade from the published repo

```bash
helm repo update
helm upgrade --install freqtrade otwld/freqtrade \
  --namespace freqtrade \
  -f values.yaml
```

## Upgrade from the local checkout

```bash
helm upgrade --install freqtrade . \
  --namespace freqtrade \
  -f examples/values-freqtrade-v2.yaml
```

## Rollback mindset

- Keep one values file per environment under version control
- Run `helm template` before upgrades that change bots, data jobs, or ingress
- Use `helm history` and `helm rollback` if a rollout fails cleanly
- Use the recovery runbook in [Operations](operations.md) if Helm metadata is unhealthy
