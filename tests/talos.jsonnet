{
  namespace: 'hf',
  namespaceMetadata: { labels: { team: 'x' } },
  images: { custos: { registry: 'mirror.example', repository: 'hf/custos', tag: 'dev-12' } },
  ampulla: { enabled: false },
  sigillum: { crds: { enabled: false } },
  libra: { bucketSecretName: 'my-bucket' },
  monitoring_stack: {
    enabled: true,
    platform: 'talos',
    alertmanager: { replicas: 2 },
    prometheus: { retention: '2d' },
  },
  // Not a library setting. Must be ignored.
  secrets: { ignored: { stringData: { a: 'b' } } },
}
