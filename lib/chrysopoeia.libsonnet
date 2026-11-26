local common = import 'common.libsonnet';
local ns = import 'namespace.libsonnet';
local vendor = import 'vendor.libsonnet';

local from = vendor.namespaces.chrysopoeia;

local fluxImages = {
  'helm-controller': 'flux-helm-controller',
  'image-reflector-controller': 'flux-image-reflector-controller',
  'source-controller': 'flux-source-controller',
};

{
  parts(s)::
    local crds =
      if s.chrysopoeia.crds.enabled
      then ns.rewrite(vendor.objects.chrysopoeia.crd, from.default, s.namespace)
      else [];

    local flux =
      if s.flux.enabled then
        local objs = ns.rewrite(vendor.objects.chrysopoeia.flux, from.flux, s.namespace);
        common.patchDeployments(
          objs, function(d)
            if std.objectHas(fluxImages, d.metadata.name) then
              common.patchContainer(
                'manager', d, function(c)
                  c { image: (common.parseDockerImage(super.image) + common.parseDockerImage(common.imageFor(s, fluxImages[d.metadata.name]))).format() }
              )
            else d
        )
      else [];

    local controller =
      if s.chrysopoeia.enabled then
        local objs = ns.rewrite(vendor.objects.chrysopoeia.default, from.default, s.namespace);
        common.patchDeployments(
          objs, function(d)
            common.patchContainer(
              'manager', d, function(c)
                common.addArgs(c, [
                  '--image-reflector-controller-hostname=image-reflector-controller-tags.%s.svc:8090' % s.namespace,
                  '--harness-proxy-host=chrysopoeia-proxy.%s.svc' % s.namespace,
                  '--harness-proxy-ca-secret-namespace=%s' % s.namespace,
                ]) { image: common.imageFor(s, 'chrysopoeia') }
            )
        )
      else [];

    local proxy =
      if s.proxy.enabled then
        local objs = ns.rewrite(vendor.objects.chrysopoeia.proxy, from.proxy, s.namespace);
        local patched = common.patchDeployments(
          objs, function(d)
            common.patchContainer(
              'proxy', d, function(c)
                c { image: common.imageFor(s, 'chrysopoeia') }
            )
        );
        local kept = [
          o
          for o in patched
          if !(o.kind == 'Issuer' && o.metadata.name == 'chrysopoeia-selfsigned-issuer')
        ];
        common.admissionObjs(s, kept)
      else [];

    common.part('10_chrysopoeia_crds', crds)
    + common.part('11_flux', flux)
    + common.part('12_chrysopoeia', controller)
    + common.part('13_chrysopoeia_proxy', proxy),
}
