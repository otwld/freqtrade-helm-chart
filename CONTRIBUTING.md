# Contributing

## Local validation

Run these commands from the repo root before opening a pull request:

```bash
helm lint .
./scripts/lint-examples.sh .
helm package . --destination /tmp
```

## Documentation

- Keep the repo docs as the source of truth
- Update the matching page under `docs/` when behavior or values change

## Releases

- Bump `Chart.yaml` intentionally
- Keep examples renderable
- Use the guidance in [`docs/releases_and_ci.md`](docs/releases_and_ci.md)
