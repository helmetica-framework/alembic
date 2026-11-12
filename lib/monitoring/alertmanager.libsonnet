local common = import '../common.libsonnet';

function(s)
  local prom = (import 'common.libsonnet')(s);

  local nsSelector = {
    matchExpressions: [
      {
        key: 'helmetica.io/monitoring',
        operator: 'Exists',
      },
    ],
  };

  local platformSpecificConfig =
    if prom.platform == prom.PlatformTalos then
      {
        spec+: {
          securityContext+: {
            fsGroup: 2000,
            runAsNonRoot: true,
            runAsUser: 1000,
          },
        },
      }
    else if prom.platform == prom.PlatformOpenShift4 then
      {}
    else
      {};

  local trimPrefix(str, prefix) =
    if std.startsWith(str, prefix) then
      std.substr(str, std.length(prefix), std.length(str) - std.length(prefix))
    else
      str;

  local globalNullRoute = {
    apiVersion: 'monitoring.coreos.com/v1alpha1',
    kind: 'AlertmanagerConfig',
    metadata: {
      name: 'global-null-route',
      namespace: s.monitoring_stack.namespace,
    },
    spec: {
      receivers: [
        {
          name: 'null',
        },
      ],
      route: {
        groupBy: [
          'alertname',
        ],
        groupInterval: '5s',
        groupWait: '0s',
        receiver: 'null',
        repeatInterval: '4h',
      },
    },
  };


  [
    {
      apiVersion: 'v1',
      kind: 'ServiceAccount',
      metadata: {
        name: 'alertmanager',
        namespace: s.monitoring_stack.namespace,
      },
    },
    {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: 'alertmanager',
        namespace: s.monitoring_stack.namespace,
      },
      spec: {
        ports: [
          {
            name: 'web',
            port: 9093,
            targetPort: 'web',
          },
          {
            name: 'reloader-web',
            port: 8080,
            targetPort: 'reloader-web',
          },
        ],
        selector: {
          'helmetica-monitoring-component': 'alertmanager',
        },
        sessionAffinity: 'ClientIP',
      },
    },
    {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'Alertmanager',
      metadata: {
        name: 'alertmanager',
        namespace: s.monitoring_stack.namespace,
        annotations: {
          'operator.prometheus.io/controller-id': '%s/prometheus-operator' % s.monitoring_stack.namespace,
        },
      },
      spec: {
        podMetadata: {
          labels: {
            'helmetica-monitoring-component': 'alertmanager',
          },
        },
        alertmanagerConfigNamespaceSelector: nsSelector,
        alertmanagerConfigSelector: {},
        image: common.imageFor(s, 'alertmanager'),
        version: trimPrefix(common.imageTag(s, 'alertmanager'), 'v'),
        portName: 'web',
        secrets: [],
        serviceAccountName: 'alertmanager',
        resources: s.monitoring_stack.alertmanager.resources,
        retention: s.monitoring_stack.alertmanager.retention,
        replicas: s.monitoring_stack.alertmanager.replicas,
        alertmanagerConfiguration: {
          name: globalNullRoute.metadata.name,
          [if std.length(s.monitoring_stack.alertmanager.global_config) > 0 then 'global']: s.monitoring_stack.alertmanager.global_config,
        },
      },
    } + platformSpecificConfig,
    globalNullRoute,
  ]
