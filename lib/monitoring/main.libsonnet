local alertmanager = import 'alertmanager.libsonnet';
local kubernetes = import 'kubernetes.libsonnet';
local operator = import 'operator.libsonnet';
local prometheus = import 'prometheus.libsonnet';

function(s)
  if !s.monitoring_stack.enabled then {} else
    local namespace = {
      apiVersion: 'v1',
      kind: 'Namespace',
      metadata: s.monitoring_stack.namespaceMetadata {
        name: s.monitoring_stack.namespace,
        labels+: { name: s.monitoring_stack.namespace },
      },
    };

    {
      '00_namespace': [ namespace ],
      '05_operator': operator(s),
      '14_alertmanager': alertmanager(s),
      '15_prometheus': prometheus(s),
      '25_kubernetes': kubernetes(s),
    }
