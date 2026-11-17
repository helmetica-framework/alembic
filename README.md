# Alembic

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

## Use from kustomize

```yaml
resources:
  - https://github.com/helmetica-framework/alembic//manifests/framework?ref=v0.1.0
```

`manifests/monitoring/<platform>` works the same way.

## Use from jsonnet

```jsonnet
local alembic = import 'alembic/lib/alembic.libsonnet';

alembic.framework({ namespace: 'my-namespace' })
```

Add the repo as a jsonnet dependency and import `alembic/lib/alembic.libsonnet`.
`settings` is merged onto the library defaults. Unknown keys are ignored.

## Bump a version

Edit `defaults.yaml` (or merge the Renovate PR), then re-render:

```bash
just vendor render gen-golden
```

Review the diff before committing. `just golden-diff` fails when the generated
trees are stale, and CI runs it on every PR.

Renovate re-renders through `postUpgradeTasks`, which only works on a self-hosted
Renovate. With the hosted app, run the three recipes by hand on the PR branch.

## Tool versions

`jsonnet`, `jsonnetfmt` and `kustomize` are pinned in the `Justfile` and run with
`go run <module>@<version>`. Renovate bumps them.
