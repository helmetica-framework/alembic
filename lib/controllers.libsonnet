local common = import 'common.libsonnet';
local ns = import 'namespace.libsonnet';
local vendor = import 'vendor.libsonnet';
local versions = std.parseYaml(importstr '../controllers.yaml');

local names = [
  name
  for name in std.objectFields(versions.controllers)
  if std.objectHas(versions.controllers[name], 'order')
];

// Extra patches beyond the image patch. Everything else is generic.
local special = {
  custos(s, d):
    common.patchContainer(
      'manager', d, function(c)
        c {
          args: common.replaceArg(
            c.args,
            '--gather-image=',
            '--gather-image=' + common.imageFor(s, 'custos')
          ),
        }
    ),

  libra(s, d):
    common.patchContainer('manager', d, function(c) common.s3Env(c, s)),
};

local render(s, name) =
  local v = versions.controllers[name];
  local up = vendor.objects[name];
  local cfg = std.get(s, name, {});
  local from = vendor.namespaceOf(name);

  local patchDeployment(d) =
    local base = common.patchContainer(
      'manager', d, function(c)
        c { image: common.imageFor(s, name) }
    );
    if std.objectHas(special, name) then special[name](s, base) else base;

  {
    crds:
      if std.get(std.get(cfg, 'crds', {}), 'enabled', true)
      then ns.rewrite(up.crd, from, s.namespace)
      else [],
    controller:
      if std.get(cfg, 'enabled', true)
      then common.patchDeployments(ns.rewrite(up.default, from, s.namespace), patchDeployment)
      else [],
  };

{
  names:: names,

  render(s, name):: render(s, name),

  parts(s)::
    std.foldl(
      function(acc, name)
        local r = render(s, name);
        local v = versions.controllers[name];
        acc
        + common.part('%02d_%s_crds' % [ v.order, name ], r.crds)
        + common.part('%02d_%s' % [ v.order + 1, name ], r.controller),
      names,
      {}
    ),
}
