# Configuration reference

`lib/alembic.libsonnet` has two functions:

```jsonnet
local alembic = import 'alembic/lib/alembic.libsonnet';

alembic.framework(settings)
alembic.monitoring(settings)
```

Both functions merge `settings` onto `defaults.yaml`. Objects merge deep. Arrays and scalars replace. Unknown keys do not change the output.

`framework(settings)` returns named parts. Each part is a list of Kubernetes objects.

`monitoring(settings)` returns named parts. It returns `{}` when `monitoring_stack.enabled` is false.

## Top level

| Setting | Type | Default | Meaning |
| --- | --- | --- | --- |
| `namespace` | string | `"helmetica-framework"` | Namespace for all framework objects. |
| `namespaceMetadata` | object | `{}` | Extra metadata for the framework Namespace. |
| `createNamespace` | bool | `true` | Render the framework Namespace object. |
| `images` | object | see [Images](#images) | Registry, repository and tag overrides. |
| `chrysopoeia` | object | see below | Chrysopoeia controller. |
| `proxy` | object | see below | Chrysopoeia proxy. |
| `flux` | object | see below | Flux controllers. |
| `custos` | object | see below | Custos controller. |
| `ampulla` | object | see below | Ampulla controller. |
| `cosi` | object | see below | COSI CRDs and controller. |
| `aludel_cloudscale` | object | see below | cloudscale.ch COSI driver. |
| `adept` | object | see below | Adept controller. |
| `sigillum` | object | see below | Sigillum controller. |
| `libra` | object | see below | Libra controller. |
| `monitoring_stack` | object | see [Monitoring](#monitoring) | Monitoring stack. |

## Controllers

A missing `enabled` key means `true`. A missing `crds.enabled` key means `true`. Set a key to `false` to leave out that output.

| Setting | Type | Default | Meaning |
| --- | --- | --- | --- |
| `chrysopoeia.enabled` | bool | `true` | Render the Chrysopoeia controller and its RBAC. |
| `chrysopoeia.crds.enabled` | bool | `true` | Render the Chrysopoeia CRDs. |
| `chrysopoeia.admission` | string | `"builtin"` | Admission mode. `"builtin"` keeps the MutatingAdmissionPolicy. `"espejote"` uses the Espejote rule instead. Any other value fails the render. |
| `proxy.enabled` | bool | `true` | Render the Chrysopoeia proxy. |
| `flux.enabled` | bool | `true` | Render the Flux source, image reflector and helm controllers. |
| `custos.enabled` | bool | `true` | Render the Custos controller. |
| `custos.crds.enabled` | bool | `true` | Render the Custos CRDs. |
| `ampulla.enabled` | bool | `true` | Render the Ampulla controller. |
| `ampulla.crds.enabled` | bool | `true` | Render the Ampulla CRDs. |
| `ampulla.default_bucket_class` | string or null | `null` | Add `--default-bucket-class=<value>` to the manager args. `null` omits the flag. |
| `ampulla.default_bucket_access_class` | string or null | `null` | Add `--default-bucket-access-class=<value>` to the manager args. `null` omits the flag. |
| `cosi.enabled` | bool | `true` | Render the COSI CRDs and controller. |
| `aludel_cloudscale.enabled` | bool | `false` | Render the cloudscale.ch COSI driver. |
| `adept.enabled` | bool | `true` | Render the Adept controller. |
| `adept.crds.enabled` | bool | `true` | Render the Adept CRDs. |
| `sigillum.enabled` | bool | `true` | Render the Sigillum controller. |
| `sigillum.crds.enabled` | bool | `true` | Render the Sigillum CRDs. |
| `libra.enabled` | bool | `true` | Render the Libra controller. |
| `libra.crds.enabled` | bool | `true` | Render the Libra CRDs. |
| `libra.bucketSecretName` | string | `"libra-billing"` | Secret that holds the S3 endpoint, bucket and keys. |

## Monitoring

Monitoring is off by default.

| Setting | Type | Default | Meaning |
| --- | --- | --- | --- |
| `monitoring_stack.enabled` | bool | `false` | Render the monitoring stack. |
| `monitoring_stack.crds.enabled` | bool | `false` | Render the Prometheus Operator CRDs. |
| `monitoring_stack.namespace` | string or null | `null` | Namespace for the stack. `null` means `<namespace>-monitoring`. |
| `monitoring_stack.namespaceMetadata` | object | `{ labels: { "helmetica.io/monitoring": "system" } }` | Extra metadata for the monitoring Namespace. The render adds the `name` label. |
| `monitoring_stack.platform` | string | `""` | Platform name. Required when `enabled` is true. See [Platforms](#platforms). |
| `monitoring_stack.alertmanager.replicas` | number | `1` | Alertmanager replica count. |
| `monitoring_stack.alertmanager.resources` | object | see `defaults.yaml` | Alertmanager resource requests and limits. |
| `monitoring_stack.alertmanager.retention` | string | `"120h"` | Alertmanager data retention. |
| `monitoring_stack.alertmanager.global_config` | object | `{}` | Alertmanager `global` config. When empty, the render leaves out the key. |
| `monitoring_stack.prometheus.retention` | string | `"8d"` | Prometheus data retention. |
| `monitoring_stack.prometheus.resources` | object | see `defaults.yaml` | Prometheus resource requests and limits. |

### Platforms

`monitoring_stack.platform` must be one of these values:

| Platform | Behavior |
| --- | --- |
| `"talos"` | Set `fsGroup: 2000`, `runAsNonRoot: true` and `runAsUser: 1000` on Alertmanager and Prometheus. |
| `"openshift4"` | Add the `tls-client-certificate-auth` scrape class and the `ocp-metrics-client-certs` secret to Prometheus. |
| `"kind"` | Add the `kubelet-serviceaccount-auth` scrape class, the kubelet ServiceMonitor and RBAC for `nodes/metrics`. |

## Images

Set `images.<name>.registry`, `images.<name>.repository` or `images.<name>.tag`. If you leave out a field, the default stays.

| Image key | Default registry and repository | Default tag |
| --- | --- | --- |
| `chrysopoeia` | `ghcr.io/helmetica-framework/chrysopoeia` | Controller version |
| `custos` | `ghcr.io/helmetica-framework/custos` | Controller version |
| `ampulla` | `ghcr.io/helmetica-framework/ampulla` | Controller version |
| `adept` | `ghcr.io/helmetica-framework/adept` | Controller version |
| `sigillum` | `ghcr.io/helmetica-framework/sigillum` | Controller version |
| `libra` | `ghcr.io/helmetica-framework/libra` | Controller version |
| `aludel-cloudscale` | `ghcr.io/helmetica-framework/aludel-cloudscale` | Controller version |
| `flux-source-controller` | `ghcr.io/fluxcd/source-controller` | `v1.10.1` |
| `flux-image-reflector-controller` | `ghcr.io/fluxcd/image-reflector-controller` | `v1.3.0` |
| `flux-helm-controller` | `ghcr.io/fluxcd/helm-controller` | `v1.7.1` |
| `alertmanager` | `quay.io/prometheus/alertmanager` | `v0.35.0` |
| `prometheus` | `quay.io/prometheus/prometheus` | `v3.16.0` |
| `prometheus-operator` | `quay.io/prometheus-operator/prometheus-operator` | `v0.95.2` |
| `prometheus-config-reloader` | `quay.io/prometheus-operator/prometheus-config-reloader` | `v0.95.2` |

The COSI controller image does not come from this table. It stays as vendored. Because there are no stable releases.

## Build inputs

`controllers` and `vendor/` are build inputs. They do not change at call time. To change an image tag, use `images.<name>.tag`.

To change a controller version, edit `defaults.yaml` and run `just gen-golden`.

## Examples

Framework only:

```jsonnet
local alembic = import 'alembic/lib/alembic.libsonnet';

alembic.framework({
  namespace: 'my-framework',
  images: { custos: { tag: 'dev-12' } },
  ampulla: { enabled: false },
  libra: { bucketSecretName: 'my-bucket' },
})
```

Framework and monitoring:

```jsonnet
local alembic = import 'alembic/lib/alembic.libsonnet';

local settings = {
  namespace: 'my-framework',
  monitoring_stack: {
    enabled: true,
    platform: 'talos',
    crds: { enabled: true },
    prometheus: { retention: '14d' },
  },
};

alembic.framework(settings) + alembic.monitoring(settings)
```

The monitoring namespace is `my-framework-monitoring` in this example.
