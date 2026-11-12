{
  namespace: 'syn-helmetica-framework',
  createNamespace: false,
  chrysopoeia: { admission: 'espejote' },
  monitoring_stack: {
    enabled: true,
    platform: 'openshift4',
    namespace: 'syn-helmetica-framework-monitoring',
    alertmanager: {
      replicas: 2,
      global_config: {
        smtp: {
          authUsername: 'example@example.com',
          from: 'example@example.com',
          requireTLS: true,
          smartHost: {
            host: 'smtp.ch.example.org',
            port: '465',
          },
          authPassword: {
            key: 'password',
            name: 'example-password',
          },
        },
      },
    },
  },
}
