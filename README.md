# Alembic

**Alembic**: the still an alchemist distills in, where a mixture is heated down to its essence.

Renders the helmetica framework and its monitoring stack into plain Kubernetes manifests, generated from the controller releases pinned in `defaults.yaml`.

Documentation: https://docs.helmetica.io/alembic/

## Development

```bash
just gen-golden   # re-render after a change to defaults.yaml or lib/
just lint
just docs         # preview the docs
```
