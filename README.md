# Alembic

**Alembic**: the still an alchemist distills in, where a mixture is heated down to its essence.

Renders the helmetica framework and its monitoring stack into plain Kubernetes
manifests. Everything is generated from the controller releases pinned in
`defaults.yaml`, so a version bump is one file plus a re-render.

## Layout

- `defaults.yaml`: controller versions, upstream dirs, image tags and the library defaults.
- `Justfile`: `vendor`, `render`, `gen-golden`, `golden-diff`, `lint`, `fmt`.
- `vendor/`: upstream kustomize dirs at the pinned tags. Generated.
- `lib/`: jsonnet library. `alembic.framework(settings)` and `alembic.monitoring(settings)`.
- `manifests/`: the default render, usable as a remote kustomize base. Generated.
- `tests/`: golden tests, one instance per platform.

## Use from jsonnet

```jsonnet
local alembic = import 'alembic/lib/alembic.libsonnet';

alembic.framework({ namespace: 'my-namespace' })
```

Add the repo as a jsonnet dependency and import `alembic/lib/alembic.libsonnet`.
`settings` is merged onto the library defaults. Unknown keys are ignored.

See `docs/config-reference.md` for all settings.

## Bump a version

Edit `defaults.yaml` (or merge the Renovate PR), then re-render:

```bash
just gen-golden
```

