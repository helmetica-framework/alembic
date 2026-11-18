local common = import '../common.libsonnet';

function(s)
  local prom = (import 'common.libsonnet')(s);

  local operator = [
    {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRoleBinding',
      metadata: {
        name: '%s:helmetica-prometheus-operator' % s.monitoring_stack.namespace,
      },
      roleRef: {
        apiGroup: 'rbac.authorization.k8s.io',
        kind: 'ClusterRole',
        name: '%s:helmetica-prometheus-operator' % s.monitoring_stack.namespace,
      },
      subjects: [
        {
          kind: 'ServiceAccount',
          name: 'prometheus-operator',
          namespace: s.monitoring_stack.namespace,
        },
      ],
    },
    {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRole',
      metadata: {
        labels+: {
          'rbac.authorization.k8s.io/aggregate-to-admin': 'true',
        },
        name: '%s:helmetica-prometheus-instance-admin' % s.monitoring_stack.namespace,
      },
      rules: [
        {
          apiGroups: [
            'monitoring.coreos.com',
          ],
          resources: [
            'alertmanagerconfigs',
            'scrapeconfigs',
            'scrapeconfigs/status',
            'servicemonitors',
            'servicemonitors/status',
            'podmonitors',
            'podmonitors/status',
            'probes',
            'probes/status',
            'prometheusrules',
            'prometheusrules/status',
          ],
          verbs: [
            '*',
          ],
        },
      ],
    },
    {
      apiVersion: 'rbac.authorization.k8s.io/v1',
      kind: 'ClusterRole',
      metadata: {
        name: '%s:helmetica-prometheus-operator' % s.monitoring_stack.namespace,
      },
      rules: [
        {
          apiGroups: [
            'monitoring.coreos.com',
          ],
          resources: [
            'alertmanagers',
            'alertmanagers/finalizers',
            'alertmanagers/status',
            'alertmanagerconfigs',
            'prometheuses',
            'prometheuses/finalizers',
            'prometheuses/status',
            'prometheusagents',
            'prometheusagents/finalizers',
            'prometheusagents/status',
            'thanosrulers',
            'thanosrulers/finalizers',
            'thanosrulers/status',
            'scrapeconfigs',
            'scrapeconfigs/status',
            'servicemonitors',
            'servicemonitors/status',
            'podmonitors',
            'podmonitors/status',
            'probes',
            'probes/status',
            'prometheusrules',
            'prometheusrules/status',
          ],
          verbs: [
            '*',
          ],
        },
        {
          apiGroups: [
            'apps',
          ],
          resources: [
            'statefulsets',
          ],
          verbs: [
            '*',
          ],
        },
        {
          apiGroups: [
            '',
          ],
          resources: [
            'configmaps',
            'secrets',
          ],
          verbs: [
            '*',
          ],
        },
        {
          apiGroups: [
            '',
          ],
          resources: [
            'pods',
          ],
          verbs: [
            'list',
            'delete',
          ],
        },
        {
          apiGroups: [
            '',
          ],
          resources: [
            'services',
            'services/finalizers',
          ],
          verbs: [
            'get',
            'create',
            'update',
            'delete',
          ],
        },
        {
          apiGroups: [
            '',
          ],
          resources: [
            'nodes',
          ],
          verbs: [
            'list',
            'watch',
          ],
        },
        {
          apiGroups: [
            '',
          ],
          resources: [
            'namespaces',
          ],
          verbs: [
            'get',
            'list',
            'watch',
          ],
        },
        {
          apiGroups: [
            'events.k8s.io',
          ],
          resources: [
            'events',
          ],
          verbs: [
            'patch',
            'create',
          ],
        },
        {
          apiGroups: [
            'networking.k8s.io',
          ],
          resources: [
            'ingresses',
          ],
          verbs: [
            'get',
            'list',
            'watch',
          ],
        },
        {
          apiGroups: [
            'storage.k8s.io',
          ],
          resources: [
            'storageclasses',
          ],
          verbs: [
            'get',
          ],
        },
        {
          apiGroups: [
            '',
          ],
          resources: [
            'endpoints',
          ],
          verbs: [
            'get',
            'create',
            'update',
            'delete',
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
            'create',
            'update',
            'delete',
          ],
        },
      ],
    },
    {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        name: 'prometheus-operator',
        namespace: s.monitoring_stack.namespace,
      },
      spec: {
        replicas: 1,
        selector: {
          matchLabels: {
            'app.kubernetes.io/component': 'controller',
            'app.kubernetes.io/name': 'prometheus-operator',
          },
        },
        template: {
          metadata: {
            annotations: {
              'kubectl.kubernetes.io/default-container': 'prometheus-operator',
            },
            labels: {
              'app.kubernetes.io/component': 'controller',
              'app.kubernetes.io/name': 'prometheus-operator',
            },
          },
          spec: {
            automountServiceAccountToken: true,
            containers: [
              {
                args: [
                  '--kubelet-service=kube-system/kubelet',
                  '--prometheus-config-reloader=%s' % common.imageFor(s, 'prometheus-config-reloader'),
                  '--kubelet-endpoints=true',
                  '--kubelet-endpointslice=true',
                  '--prometheus-instance-namespaces=%s' % s.monitoring_stack.namespace,
                  '--thanos-ruler-instance-namespaces=%s' % s.monitoring_stack.namespace,
                  '--alertmanager-instance-namespaces=%s' % s.monitoring_stack.namespace,
                  '--watch-referenced-objects-in-all-namespaces',
                  '--controller-id=%s/prometheus-operator' % s.monitoring_stack.namespace,
                ],
                env: [
                  {
                    name: 'GOGC',
                    value: '30',
                  },
                ],
                image: common.imageFor(s, 'prometheus-operator'),
                name: 'prometheus-operator',
                ports: [
                  {
                    containerPort: 8080,
                    name: 'http',
                  },
                ],
                resources: {
                  limits: {
                    cpu: '200m',
                    memory: '200Mi',
                  },
                  requests: {
                    cpu: '100m',
                    memory: '100Mi',
                  },
                },
                securityContext: {
                  allowPrivilegeEscalation: false,
                  capabilities: {
                    drop: [
                      'ALL',
                    ],
                  },
                  readOnlyRootFilesystem: true,
                },
              },
            ],
            nodeSelector: {
              'kubernetes.io/os': 'linux',
            },
            serviceAccountName: 'prometheus-operator',
          },
        },
      },
    },
    {
      apiVersion: 'v1',
      automountServiceAccountToken: false,
      kind: 'ServiceAccount',
      metadata: {
        name: 'prometheus-operator',
        namespace: s.monitoring_stack.namespace,
      },
    },
    {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: 'prometheus-operator',
        namespace: s.monitoring_stack.namespace,
      },
      spec: {
        clusterIP: 'None',
        ports: [
          {
            name: 'http',
            port: 8080,
            targetPort: 'http',
          },
        ],
        selector: {
          'app.kubernetes.io/component': 'controller',
          'app.kubernetes.io/name': 'prometheus-operator',
        },
      },
    },
  ];

  if prom.platform == prom.PlatformOpenShift4 then
    operator
  else if prom.platform == prom.PlatformTalos then
    operator
  else if prom.platform == prom.PlatformKind then
    operator
  else
    []
