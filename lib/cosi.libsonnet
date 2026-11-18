// COSI and the cloudscale.ch driver. Both come from the aludel-cloudscale
// repo, but they are separate: the CRDs and controller are upstream COSI, the
// driver is one provider of BucketClasses.
local common = import 'common.libsonnet';
local ns = import 'namespace.libsonnet';
local vendor = import 'vendor.libsonnet';

local cosiFrom = 'container-object-storage-system';
local aludelFrom = 'aludel-cloudscale-system';
local aludelImage = 'aludel-cloudscale';

{
  parts(s)::
    local cosiObjects =
      if s.cosi.enabled
      then ns.rewrite(vendor.objects.cosi.crd, cosiFrom, s.namespace)
      else [];

    local cosiCrds = [
      o
      for o in cosiObjects
      if o.kind == 'CustomResourceDefinition'
    ];
    local cosiController = [
      o
      for o in cosiObjects
      if o.kind != 'CustomResourceDefinition'
    ];

    local aludelObjects =
      if s.aludel_cloudscale.enabled
      then ns.rewrite(vendor.objects['aludel-cloudscale'].manager, aludelFrom, s.namespace)
      else [];
    local aludel = common.patchDeployments(
      aludelObjects,
      function(d)
        common.patchContainer(
          aludelImage, d, function(c) c { image: common.imageFor(s, aludelImage) }
        )
    );

    common.part('10_cosi_crds', cosiCrds)
    + common.part('11_cosi', cosiController)
    + common.part('15_aludel_cloudscale', aludel),
}
