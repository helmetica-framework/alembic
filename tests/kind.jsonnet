{
  namespace: 'syn-helmetica-framework',
  monitoring_stack: {
    enabled: true,
    platform: 'kind',
    namespace: 'syn-helmetica-framework-monitoring',
    crds: { enabled: true },
  },
}
