{
  namespace: 'syn-helmetica-framework',
  createNamespace: false,
  chrysopoeia: { admission: 'espejote' },
  monitoring_stack: {
    enabled: true,
    platform: 'openshift4',
    namespace: 'syn-helmetica-framework-monitoring',
  },
}
