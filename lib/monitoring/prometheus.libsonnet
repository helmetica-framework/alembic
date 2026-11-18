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
      {
        spec+: {
          scrapeClasses+: [
            {
              name: 'tls-client-certificate-auth',
              tlsConfig: {
                ca: {},
                cert: {},
                certFile: '/etc/prometheus/secrets/ocp-metrics-client-certs/tls.crt',
                insecureSkipVerify: true,
                keyFile: '/etc/prometheus/secrets/ocp-metrics-client-certs/tls.key',
              },
            },
          ],
          secrets+: [
            'ocp-metrics-client-certs',
          ],
        },
      }
    else if prom.platform == prom.PlatformKind then
      {
        spec+: {
          scrapeClasses+: [
            {
              // The kubelet authorizes the ServiceAccount token against nodes/metrics.
              name: 'kubelet-serviceaccount-auth',
              authorization: {
                credentialsFile: '/var/run/secrets/kubernetes.io/serviceaccount/token',
              },
              tlsConfig: {
                // kubelet serving certificates are self-signed on kind.
                insecureSkipVerify: true,
              },
            },
          ],
        },
      }
    else
      {};

  local trimPrefix(str, prefix) =
    if std.startsWith(str, prefix) then
      std.substr(str, std.length(prefix), std.length(str) - std.length(prefix))
    else
      str;

  [
    {
      apiVersion: 'v1',
      kind: 'ServiceAccount',
      metadata: {
        name: 'prometheus-stack',
        namespace: s.monitoring_stack.namespace,
      },
    },
    {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRole',
      metadata: {
        name: '%s:helmetica-prometheus-stack' % s.monitoring_stack.namespace,
      },
      rules: [
        {
          apiGroups: [
            '',
          ],
          resources: [
            'services',
            'nodes',
            'endpoints',
            'pods',
          ],
          verbs: [
            'get',
            'list',
            'watch',
          ],
        },
        {
          apiGroups: [
            'discovery.k8s.io',
          ],
          resources: [
            'endpointslices',
          ],
          verbs: [
            'get',
            'list',
            'watch',
          ],
        },
        {
          nonResourceURLs: [
            '/metrics',
          ],
          verbs: [
            'get',
          ],
        },
      ] + if prom.platform == prom.PlatformKind then [
        {
          apiGroups: [
            '',
          ],
          resources: [
            'nodes/metrics',
          ],
          verbs: [
            'get',
          ],
        },
      ] else [],
    },
    {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRoleBinding',
      metadata: {
        name: '%s:helmetica-prometheus-stack' % s.monitoring_stack.namespace,
      },
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'ClusterRole',
        name: '%s:helmetica-prometheus-stack' % s.monitoring_stack.namespace,
      },
      subjects: [
        {
          kind: 'ServiceAccount',
          name: 'prometheus-stack',
          namespace: s.monitoring_stack.namespace,
        },
      ],
    },
    {
      apiVersion: 'monitoring.coreos.com/v1',
      kind: 'Prometheus',
      metadata: {
        name: 'stack',
        namespace: s.monitoring_stack.namespace,
        annotations: {
          'operator.prometheus.io/controller-id': '%s/prometheus-operator' % s.monitoring_stack.namespace,
        },
      },
      spec: {
        alerting: {
          alertmanagers: [
            {
              apiVersion: 'v2',
              name: 'alertmanager',
              namespace: s.monitoring_stack.namespace,
              port: 'web',
            },
          ],
        },
        serviceAccountName: 'prometheus-stack',
        replicas: 1,
        resources: s.monitoring_stack.prometheus.resources,
        retention: s.monitoring_stack.prometheus.retention,
        rules: {
          alert: {},
        },
        scrapeInterval: '30s',
        enforcedNamespaceLabel: 'namespace',
        excludedFromEnforcement: [
          {
            group: 'monitoring.coreos.com',
            namespace: s.monitoring_stack.namespace,
            resource: 'servicemonitors',
          },
        ],
        // TODO(bastjan)
        // We probably want to enforce empty selectors for instance namespaces.
        // We need it to allow kubelet monitoring without having to add a label to the kube-system namespace.
        ignoreNamespaceSelectors: false,
        podMonitorNamespaceSelector: nsSelector,
        probeNamespaceSelector: nsSelector,
        ruleNamespaceSelector: nsSelector,
        scrapeConfigNamespaceSelector: nsSelector,
        serviceMonitorNamespaceSelector: nsSelector,
        serviceMonitorSelector: {},
        podMonitorSelector: {},
        ruleSelector: {},
        shards: 1,
        storage: {
          volumeClaimTemplate: {
            metadata: {},
            spec: {
              resources: {
                requests: {
                  storage: '10Gi',
                },
              },
            },
            status: {},
          },
        },
        image: common.imageFor(s, 'prometheus'),
        version: trimPrefix(common.imageTag(s, 'prometheus'), 'v'),
        web: {
          httpConfig: {
            headers: {
              contentSecurityPolicy: "frame-ancestors 'none'",
            },
          },
        },
      },
    } + platformSpecificConfig,
  ]
