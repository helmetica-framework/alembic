{
  namespace: 'helmetica-framework',
  namespaceMetadata: {},
  createNamespace: true,
  images: {
    // registry and repository only. Tags come from controllers.yaml.
    chrysopoeia: { registry: 'ghcr.io', repository: 'helmetica-framework/chrysopoeia' },
    custos: { registry: 'ghcr.io', repository: 'helmetica-framework/custos' },
    ampulla: { registry: 'ghcr.io', repository: 'helmetica-framework/ampulla' },
    adept: { registry: 'ghcr.io', repository: 'helmetica-framework/adept' },
    sigillum: { registry: 'ghcr.io', repository: 'helmetica-framework/sigillum' },
    libra: { registry: 'ghcr.io', repository: 'helmetica-framework/libra' },
    'flux-source-controller': { registry: 'ghcr.io', repository: 'fluxcd/source-controller' },
    'flux-image-reflector-controller': { registry: 'ghcr.io', repository: 'fluxcd/image-reflector-controller' },
    'flux-helm-controller': { registry: 'ghcr.io', repository: 'fluxcd/helm-controller' },
  },
  chrysopoeia: { enabled: true, crds: { enabled: true }, admission: 'builtin' },
  proxy: { enabled: true },
  flux: { enabled: true },
  custos: { enabled: true, crds: { enabled: true } },
  ampulla: { enabled: true, crds: { enabled: true } },
  adept: { enabled: true, crds: { enabled: true } },
  sigillum: { enabled: true, crds: { enabled: true } },
  libra: { enabled: true, crds: { enabled: true }, bucketSecretName: 'libra-billing' },
  monitoring_stack: {},  // Unit 5
}
